/* global __coffeescriptShare */
import React from 'react'
import { withTracker } from 'meteor/react-meteor-data'
import { _ } from 'meteor/underscore'

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
  Meteor.subscribe(`${share.eventName}.Volunteers.ShiftSignups.byUser`, bookedUserId).ready()
  Meteor.subscribe(`${share.eventName}.Volunteers.ProjectSignups.byUser`, bookedUserId).ready()
  Meteor.subscribe(`${share.eventName}.Volunteers.LeadSignups.byUser`, bookedUserId).ready()
  let allShifts = []
  const sel = { userId: bookedUserId, status: { $in: ['confirmed', 'pending'] } }
  const shiftSignups = share.ShiftSignups.find(sel)
    .map(signup => ({ ...signup, type: 'shift' }))
  const projectSignups = share.ProjectSignups.find(sel)
    .map(signup => ({ ...signup, type: 'project' }))
  const leadSignups = share.LeadSignups.find(sel)
    .map(signup => ({ ...signup, type: 'lead' }))
  allShifts = _.sortBy([...leadSignups, ...shiftSignups, ...projectSignups], s => s.start)

  return {
    allShifts,
  }
})(BookedTableComponent)
