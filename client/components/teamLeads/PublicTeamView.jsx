import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'
import React, { useContext } from 'react'
import { useParams } from 'react-router-dom'

import { SignupsList } from '../shifts/SignupsList.jsx'
import { reactContext } from '../../clientInit'
import { T } from '../common/i18n'

export const PublicTeamView = () => {
  const Volunteers = useContext(reactContext)
  const { teamId } = useParams()
  const { team, ready } = useTracker(() => {
    const teamSub = Meteor.subscribe(`${Volunteers.eventName}.Volunteers.team`, { _id: teamId })

    let foundTeam = {}
    if (teamSub.ready()) {
      foundTeam = Volunteers.collections.team.findOne(teamId)
    }

    return { team: foundTeam, ready: teamSub.ready() }
  }, [teamId])

  return (
    <div className="container">
      <div className="row">
        {team && (
          <div className="card">
            <div className="card-header">
              <h5>{team.name}</h5>
              {team.email && (
                <h5 className="text-muted text-right"><T>contact</T>: {team.email}</h5>
              )}
            </div>
            <p className="m-2">{team.description}</p>
          </div>
        )}
      </div>
      <h3 className="pt-2"><T>shifts_in_this_team</T></h3>
      {ready && team._id && (
        <SignupsList filters={{ teams: [team._id] }} />
      )}
    </div>
  )
}
