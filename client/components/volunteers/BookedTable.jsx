/* global __coffeescriptShare */
import React from 'react'
import { Meteor } from 'meteor/meteor'
import { withTracker } from 'meteor/react-meteor-data'

import { collections } from '../../../both/collections/initCollections'
import { SignupUserRowView } from './SignupUserRowView.jsx'

export const BookedTableComponent = ({
  allShifts,
}) => (
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

const share = __coffeescriptShare

export const BookedTable = withTracker(({ userId }) => {
  const bookedUserId = userId || Meteor.userId()
  Meteor.subscribe(`${share.eventName}.Volunteers.Signups.byUser`, bookedUserId).ready()

  const sel = { userId: bookedUserId, status: { $in: ['confirmed', 'pending'] } }
  // TODO when moving to methods improve sort here. As mini mongo doesn't support aggregations
  // can't do it without querying for each shift
  return {
    allShifts: collections.signups.find(sel, { sort: { type: 1, start: 1 } }).fetch(),
  }
})(BookedTableComponent)
