import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import { useTracker } from 'meteor/react-meteor-data'
import React, { useContext } from 'react'

import { collections } from '../../../both/collections/initCollections'
import { findOrgUnit } from '../../../both/utils/unit'
import { SignupShiftRow } from './SignupShiftRow.jsx'
import { reactContext } from '../../clientInit'

// TODO Replace all this weird local collection stuff with just a method call
const DatesLocal = new Mongo.Collection(null)

// DatesLocal contains all shifts (dates) related to a particular title and parentId
const addLocalDatesCollection = (duties, type, filter) => {
  duties.find(filter).forEach((duty) => {
    const orgUnit = findOrgUnit(duty.parentId)
    DatesLocal.upsert(duty._id, {
      type,
      team: orgUnit && orgUnit.unit,
      signup: collections.signups.findOne({
        userId: Meteor.userId(),
        shiftId: duty._id,
      }),
      ...duty,
    })
  })
}

export function ShiftSignupModalContents({
  duty,
}) {
  const Volunteers = useContext(reactContext)
  const eventName = Volunteers?.eventName || 'nowhere2022'
  const { allDates } = useTracker(() => {
    const { type, title, parentId } = duty
    const userId = Meteor.userId()
    const subs = [
      Meteor.subscribe(`${eventName}.Volunteers.duties`, type, { title, parentId }),
      Meteor.subscribe(`${eventName}.Volunteers.Signups.byUser`, userId),
    ]
    if (subs.every(sub => sub.ready())) {
      addLocalDatesCollection(collections.dutiesCollections[type], type, { title, parentId })
    }
    return {
      allDates: DatesLocal.find({ title }, { sort: { start: 1 } }).fetch(),
    }
  }, [duty])
  return (
    <>
      {allDates.map(date => (
        <div key={date._id} className="list-item row align-items-center px-2">
          <SignupShiftRow {...date} />
        </div>
      ))}
    </>
  )
}
