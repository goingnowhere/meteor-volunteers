import React, { useContext, useState } from 'react'
import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'
import { LeadListItemGrouped } from './LeadListItemGrouped.jsx'
import { SignupsListTeam } from '../volunteers/SignupsListTeam.jsx'
import { reactContext } from '../../clientInit'
import { T } from '../common/i18n'

export function SignupsList({
  dutyType, filters = {}, quirks, skills,
}) {
  const { collections, eventName } = useContext(reactContext)
  const [limit, setLimit] = useState(8)
  const { allTeams, showLoadMore } = useTracker(() => {
    if (quirks || skills) {
      Meteor.subscribe(`${eventName}.Volunteers.team.ByUserPref`, quirks, skills)
    } else {
      Meteor.subscribe(`${eventName}.Volunteers.team`)
    }

    const query = {
      ...(filters.skills ? { skills: { $in: filters.skills } } : {}),
      ...(filters.quirks ? { quirks: { $in: filters.quirks } } : {}),
    }
    // teams are ordered using the score that is calculated by considering
    // the priority of the shifts associated with each team
    // We used to limit here but it meant we didn't know if we had more results, so istead get
    // everything
    const allTeamsCursor = collections.team
      .find(query, { sort: { userpref: -1, totalscore: -1 } })
    // Doesn't work well for build/strike. Temp fix until we can add a better sort/search
    return dutyType === 'project' ? {
      allTeams: allTeamsCursor.fetch(),
      showLoadMore: false,
    } : {
      allTeams: allTeamsCursor.fetch().slice(0, limit),
      showLoadMore: allTeamsCursor.count() >= limit,
    }
  }, [limit, filters, quirks, skills, dutyType])

  return (
    <div className="container-fluid p-0">
      {allTeams.map(team =>
        (dutyType === 'lead' ? (
          <LeadListItemGrouped key={team._id} teamId={team._id} />
        ) : (
          <SignupsListTeam key={team._id} team={team} filters={filters} dutyType={dutyType} />
        )))}
      {showLoadMore && (
        <div className="row align-content-right no-gutters">
          <div className="col">
            <button
              type="button"
              className="btn btn-light btn-primary"
              onClick={() => setLimit(limit + 2)}
            ><T>load_more_teams</T>
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
