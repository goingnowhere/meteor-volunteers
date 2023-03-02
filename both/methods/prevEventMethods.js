import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

import { signupDetailPipeline } from './aggregations'

export function initPrevEventMethods(volunteers) {
  const { prevEventCollections, services: { auth } } = volunteers

  return {
    listTeams: new ValidatedMethod({
      name: 'prev-event.team.list',
      validate: null,
      mixins: [auth.mixins.isAnyLead],
      run() {
        return prevEventCollections.team.find({}, { name: true }).fetch()
      },
    }),
    listTeamVolunteers: new ValidatedMethod({
      name: 'prev-event.team-volunteers.list',
      validate: ({ teamId }) => check(teamId, String),
      mixins: [auth.mixins.isAnyLead],
      run({ teamId }) {
        // return prevEventCollections.signups.find({ parentId: teamId }).fetch()
        if (Meteor.isServer) {
          return prevEventCollections.signups.aggregate([
            {
              $match: { parentId: teamId },
            },
            ...signupDetailPipeline(prevEventCollections, ['user', 'duty']),
          ])
        }
        return []
      },
    }),
  }
}
