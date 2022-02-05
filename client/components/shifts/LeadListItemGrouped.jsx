import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'
import React, { useContext, useState } from 'react'

import { T } from '../common/i18n'
import { LeadListItem } from './LeadListItem.jsx'
import { applyCall } from '../../utils/signups'
import { collections } from '../../../both/collections/initCollections'
import { reactContext } from '../../clientInit'

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

export function LeadListItemGrouped({ teamId }) {
  const _Volunteers = useContext(reactContext)
  console.log(_Volunteers)
  const Volunteers = { eventName: 'nowhere2022' }
  const [limit, setLimit] = useState(2)
  const loadMoreLeads = () => setLimit(limit + 2)
  const { allLeads, loaded, showLoadMore } = useTracker(() => {
    const userId = Meteor.userId()

    const leadSub = Meteor.subscribe(`${Volunteers.eventName}.Volunteers.duties`, 'lead', { parentId: teamId }, limit)
    const leadSignupSub = Meteor.subscribe(`${Volunteers.eventName}.Volunteers.Signups.byUser`, userId, ['lead'])
    const isLoaded = leadSub.ready() && leadSignupSub.ready()
    return {
      loaded: isLoaded,
      showLoadMore: isLoaded && collections.lead.find({ parentId: teamId }).count() >= limit,
      allLeads: !isLoaded ? [] : collections.lead.find({ parentId: teamId }).map(lead => ({
        ...lead,
        team: getTeam('lead', lead.parentId),
        signup: collections.leadSignups?.findOne({ userId, shiftId: lead._id }),
        type: 'lead',
      })),
    }
  }, [limit, _Volunteers])
  return (
    <div className="row justify-content-between align-content-center no-gutters">
      {loaded && allLeads.length > 0 && (
        <div className="container-fluid signupsListItem">
          {allLeads.map(lead =>
            <LeadListItem key={lead._id} lead={lead} apply={applyCall(Volunteers, lead)} />)}
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
}
