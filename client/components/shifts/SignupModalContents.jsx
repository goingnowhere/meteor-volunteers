/* global __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import { withTracker } from 'meteor/react-meteor-data'
import React, { Fragment } from 'react'

import { collections } from '../../../both/collections/initCollections'
import { findOrgUnit } from '../../../both/collections/unit'
import { DutiesListItemDate } from './DutiesListItemDate.jsx'

const SignupModalContentsComponent = ({
  allDates,
}) => (
  <Fragment>
    {allDates.map(date => (
      <div key={date._id} className="list-item row align-items-center px-2">
        <DutiesListItemDate {...date} />
      </div>
    ))}
  </Fragment>
)

// TODO We should replace all of this with a method

const share = __coffeescriptShare

// client side collection
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

export const SignupModalContents = withTracker(({ duty, ...props }) => {
  const { type, title, parentId } = duty
  const userId = Meteor.userId()
  const subs = [
    Meteor.subscribe(`${share.eventName}.Volunteers.duties`, type, { title, parentId }),
    Meteor.subscribe(`${share.eventName}.Volunteers.Signups.byUser`, userId),
  ]
  if (subs.every(sub => sub.ready())) {
    addLocalDatesCollection(collections.dutiesCollections[type], type, { title, parentId })
  }
  return {
    duty,
    ...props,
    allDates: DatesLocal.find({ title }, { sort: { start: 1 } }).fetch(),
  }
})(SignupModalContentsComponent)
