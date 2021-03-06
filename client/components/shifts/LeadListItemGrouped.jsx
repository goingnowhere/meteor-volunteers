/* global __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { withTracker } from 'meteor/react-meteor-data'
import React from 'react'

import { T } from '../common/i18n'
import { LeadListItem } from './LeadListItem.jsx'
import { applyCall } from '../../utils/signups'
import { collections } from '../../../both/collections/initCollections'

export const LeadListItemGroupedComponent = ({
  allLeads,
  loaded,
  showLoadMore,
  loadMoreLeads,
}) => (
  <div className="row justify-content-between align-content-center no-gutters">
    {loaded && allLeads.length > 0 && (
      <div className="container-fluid signupsListItem">
        {allLeads.map(lead => <LeadListItem key={lead._id} lead={lead} apply={applyCall(lead)} />)}
        {showLoadMore && (
          <div className="row align-content-right no-gutters">
            <div className="col-md-2 offset-md-8">
              <button
                className="btn btn-light btn-primary"
                type="button"
                onClick={loadMoreLeads}
              >
                <T>load_more_leads</T>
              </button>
            </div>
          </div>
        )}
      </div>
    )}
  </div>
)

const share = __coffeescriptShare

const getTeam = (type, parentId) => {
  // if (['shift', 'task'].includes(type)) {
  //   return collections.team.findOne(parentId)
  // }
  const team = collections.team.findOne(parentId)
  if (team) return { ...team, type: 'team' }
  const department = collections.department.findOne(parentId)
  if (department) return { ...department, type: 'department' }
  const division = collections.division.findOne(parentId)
  return { ...division, type: 'division' }
}

const mapProps = ({ teamId, reactiveLimit }) => {
  const userId = Meteor.userId()
  const limit = reactiveLimit.get()

  const leadSub = Meteor.subscribe(`${share.eventName}.Volunteers.Lead`, { parentId: teamId }, limit)
  const leadSignupSub = Meteor.subscribe(`${share.eventName}.Volunteers.Signups.byUser`, userId, ['lead'])
  const loaded = leadSub.ready() && leadSignupSub.ready()

  const showLoadMore = loaded && collections.lead.find({ parentId: teamId }).count() >= limit
  const allLeads = !loaded ? [] : collections.lead.find({ parentId: teamId }).map(lead => ({
    ...lead,
    team: getTeam('lead', lead.parentId),
    signup: collections.leadSignups.findOne({ userId, shiftId: lead._id }),
    type: 'lead',
  }))
  // _.filter(leads,(lead) -> ! lead.signup.status? )

  const loadMoreLeads = () => {
    reactiveLimit.set(limit + 2)
  }

  return {
    allLeads,
    loaded,
    showLoadMore,
    loadMoreLeads,
  }
}

// TODO probably need to store WithTracker on the instance
export const LeadListItemGrouped = (props) => {
  const reactiveLimit = new ReactiveVar(2)
  const WithTracker = withTracker(mapProps)(LeadListItemGroupedComponent)
  return (
    <WithTracker reactiveLimit={reactiveLimit} {...props} />
  )
}
