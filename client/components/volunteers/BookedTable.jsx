/* global __coffeescriptShare */
import React from 'react'
import { withTracker } from 'meteor/react-meteor-data'
import { _ } from 'meteor/underscore'

import { SignupUserRowViewContainer } from './SignupUserRowView.jsx'

export const BookedTable = ({
  allShifts,
}) => (
  <div className="container-fluid p-0 bookedTable">
    <div className="row">
      <div className="container-fluid">
        {allShifts.map(shift => (
          <div key={shift._id} className="flex-column bookedTableItem p-0">
            <SignupUserRowViewContainer signup={shift} />
          </div>
        ))}
      </div>
    </div>
  </div>
)

const share = __coffeescriptShare

export const BookedTableContainer = withTracker(({ userId }) => {
  const bookedUserId = userId || Meteor.userId()
  const loaded = [
    Meteor.subscribe('nowhere2018.Volunteers.ShiftSignups.byUser', bookedUserId).ready(),
    Meteor.subscribe('nowhere2018.Volunteers.ProjectsSignups.byUser', bookedUserId).ready(),
    Meteor.subscribe('nowhere2018.Volunteers.LeadSignups.byUser', bookedUserId).ready(),
  ]
  let allShifts = []
  if (loaded) {
    const sel = { userId: bookedUserId, status: { $in: ['confirmed', 'pending'] } }
    const shiftSignups = share.ShiftSignups.find(sel)
      .map(signup => ({ ...signup, type: 'shift' }))
    const projectSignups = share.ProjectSignups.find(sel)
      .map(signup => ({ ...signup, type: 'project' }))
    const leadSignups = share.LeadSignups.find(sel)
      .map(signup => ({ ...signup, type: 'lead' }))
    allShifts = _.sortBy([...leadSignups, ...shiftSignups, ...projectSignups], s => s.start)
  }
  return {
    allShifts,
  }
})(BookedTable)
