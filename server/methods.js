/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

import { dutyTypes } from '../both/collections/volunteer'
import { collections } from '../both/collections/initCollections'
import { getDuties, getTeamStats, getDeptStats } from '../both/stats'

const share = __coffeescriptShare

const moment = extendMoment(Moment)

export const initServerMethods = (eventName) => {
  const prefix = `${eventName}.Volunteers`
  new ValidatedMethod({
    name: `${prefix}.getProjectStaffing`,
    validate(projectId) { check(projectId, String) },
    run(projectId) {
      const project = share.Projects.findOne(projectId)
      if (project) {
        let days = []
        const range = moment.range(project.start, project.end).by('days')
        days = Array.from(range)
        const signups = collections.signups.find({ shiftId: projectId, status: 'confirmed' }).fetch()

        const confirmed = days.map((day) => {
          const thisday = signups.filter((signup) => (day.isBetween(signup.start, signup.end, 'days', '[]')))
          return thisday.length
        })
        return confirmed
      }
      throw new Meteor.Error('InternalError', 'Project not found')
    },
  })

  Meteor.methods({
    'signups.list'(query) {
      check(query, Object)
      if (!share.isManagerOrLead(this.userId, [query.parentId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collections.signups.aggregate([
        {
          $match: query,
        }, {
          $lookup: {
            from: share.Department._name,
            localField: 'parentId',
            foreignField: '_id',
            as: 'dept',
          },
        }, {
          $unwind: {
            path: '$dept',
            preserveNullAndEmptyArrays: true,
          },
        }, {
          $lookup: {
            from: share.Team._name,
            localField: 'parentId',
            foreignField: '_id',
            as: 'team',
          },
        }, {
          $unwind: {
            path: '$team',
            preserveNullAndEmptyArrays: true,
          },
        }, {
          $lookup: {
            from: share.Lead._name,
            localField: 'shiftId',
            foreignField: '_id',
            as: 'lead',
          },
        }, {
          $lookup: {
            from: share.TeamShifts._name,
            localField: 'shiftId',
            foreignField: '_id',
            as: 'shift',
          },
        }, {
          $lookup: {
            from: share.Projects._name,
            localField: 'shiftId',
            foreignField: '_id',
            as: 'project',
          },
        }, {
          $addFields: {
            duty: {
              $switch: {
                branches: [
                  {
                    case: { $gt: [{ $size: '$shift' }, 0] },
                    then: { $arrayElemAt: ['$shift', 0] },
                  }, {
                    case: { $gt: [{ $size: '$lead' }, 0] },
                    then: { $arrayElemAt: ['$lead', 0] },
                  }, {
                    case: { $gt: [{ $size: '$project' }, 0] },
                    then: { $arrayElemAt: ['$project', 0] },
                  },
                ],
              },
            },
          },
        }, {
          $lookup: {
            from: Meteor.users._name,
            let: { userId: '$userId' },
            pipeline: [
              {
                $match: { $expr: { $eq: ['$_id', '$$userId'] } },
              }, {
                // Only return public user fields
                $project: {
                  emails: true,
                  profile: true,
                },
              },
            ],
            as: 'user',
          },
        }, {
          $unwind: { path: '$user' },
        },
      ])
    },
  })

  new ValidatedMethod({
    name: `${prefix}.getTeamDutyStats`,
    validate({ type, teamId, date }) {
      check(teamId, String)
      check(type, Match.OneOf(...dutyTypes))
      check(date, Match.Maybe(Date))
    },
    run({ type, teamId, date }) {
      if (!share.isManagerOrLead(this.userId, [teamId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      let query = { parentId: teamId }
      if (date) {
        const startOfDay = moment(date).startOf('day')
        const endOfDay = moment(date).endOf('day')
        query = {
          $and: [
            query,
            { start: { $gte: startOfDay.toDate(), $lte: endOfDay.toDate() } },
          ],
        }
      }
      const duties = getDuties(query, type)
      // TODO get usernames in lead page so remove need for this?
      const userIds = new Set(duties.flatMap((duty) => duty.volunteers))
      const users = Meteor.users
        .find({ _id: { $in: Array.from(userIds) } }, { fields: { profile: true } }).fetch()
      return { users, duties }
    },
  })

  new ValidatedMethod({
    name: `${prefix}.getTeamStats`,
    validate({ teamId }) {
      check(teamId, String)
    },
    run({ teamId }) {
      if (!share.isManagerOrLead(this.userId, [teamId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return getTeamStats(teamId)
    },
  })

  new ValidatedMethod({
    name: `${prefix}.getDeptStats`,
    validate({ deptId }) {
      check(deptId, String)
    },
    run({ deptId }) {
      if (!share.isManagerOrLead(this.userId, [deptId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return getDeptStats(deptId)
    },
  })

  new ValidatedMethod({
    name: `${prefix}.rotas.findOne`,
    validate({ rotaId }) {
      check(rotaId, String)
    },
    run({ rotaId }) {
      console.log('finding rota', rotaId)
      const rota = collections.rotas.findOne(rotaId)
      if (!rota) throw new Meteor.Error(404, 'Not Found')
      if (rota.policy === 'adminOnly' && !share.isManagerOrLead(this.userId, [rota.parentId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return rota
    },
  })
}
