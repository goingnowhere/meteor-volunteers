import React from 'react'
// import React, { useContext } from 'react'
import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'

import { collections } from '../../../both/collections/initCollections'
// import { reactContext } from '../../clientInit'
import { SignupUserRowView } from './SignupUserRowView.jsx'

export const BookedTable = ({
  userId,
}) => {
  // Can't use context from a component within a blaze template
  // const Volunteers = useContext(reactContext)
  const eventName = 'nowhere2022' // Volunteers.eventName
  const allShifts = useTracker(() => {
    const bookedUserId = userId || Meteor.userId()
    Meteor.subscribe(`${eventName}.Volunteers.Signups.byUser`, bookedUserId).ready()

    const sel = { userId: bookedUserId, status: { $in: ['confirmed', 'pending'] } }
    // TODO when moving to methods improve sort here. As mini mongo doesn't support aggregations
    // can't do it without querying for each shift
    return collections.signups.find(sel, { sort: { type: 1, start: 1 } }).fetch()
  }, [eventName, userId])
  return (
    <div className="container-fluid p-0 bookedTable">
      <div className="row">
        <div className="container-fluid">
          {allShifts.map(shift => (
            <div key={shift._id} className="flex-column bookedTableItem p-0">
              <SignupUserRowView signup={shift} />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
