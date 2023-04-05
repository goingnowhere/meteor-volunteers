import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'
import React, { useContext } from 'react'

import { LeadListItem } from './LeadListItem.jsx'
import { applyCall } from '../../utils/signups'
import { reactContext } from '../../clientInit'

const getTeam = (collections, parentId) => {
  const team = collections.team.findOne(parentId)
  if (team) return { ...team, type: 'team' }
  const department = collections.department.findOne(parentId)
  if (department) return { ...department, type: 'department' }
  const division = collections.division.findOne(parentId)
  return { ...division, type: 'division' }
}

export function LeadListItemGrouped({ teamId }) {
  const Volunteers = useContext(reactContext)
  const { collections, eventName } = Volunteers
  const { allLeads, loaded } = useTracker(() => {
    const userId = Meteor.userId()

    const leadSub = Meteor.subscribe(`${eventName}.Volunteers.duties`, 'lead', { parentId: teamId })
    const leadSignupSub = Meteor.subscribe(`${eventName}.Volunteers.Signups.byUser`, userId, ['lead'])
    const isLoaded = leadSub.ready() && leadSignupSub.ready()
    const leadQuery = { parentId: teamId }
    return {
      loaded: isLoaded,
      allLeads: !isLoaded ? [] : collections.lead.find(leadQuery).map(lead => ({
        ...lead,
        team: getTeam(collections, lead.parentId),
        signup: collections.leadSignups?.findOne({ userId, shiftId: lead._id }),
        type: 'lead',
      })).filter(lead => lead.signedUp === 0),
    }
  }, [eventName, collections])
  return (
    <div className="row justify-content-between align-content-center no-gutters">
      {loaded && allLeads.length > 0 && (
        <div className="container-fluid signupsListItem">
          {allLeads.map(lead =>
            <LeadListItem key={lead._id} lead={lead} apply={applyCall(Volunteers, lead)} />)}
        </div>
      )}
    </div>
  )
}
