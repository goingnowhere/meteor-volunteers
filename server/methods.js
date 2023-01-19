import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import moment from 'moment-timezone'

import { dutyTypes } from '../both/collections/schemas/volunteer'

export const initServerMethods = (volunteersClass) => {
  const { collections, eventName, services } = volunteersClass
  const prefix = `${eventName}.Volunteers`

  Meteor.methods({
    'signups.list'(query) {
      check(query, Object)
      const teamIds = (query.parentId?.$in ?? [query.parentId])
        .filter(unitId => services.auth.isLead(this.userId, unitId))
      if (teamIds.length < 1) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      const restrictedQuery = {
        ...query,
        parentId: { $in: teamIds },
      }
      return collections.signups.aggregate([
        {
          $match: restrictedQuery,
        }, {
          $lookup: {
            from: collections.department._name,
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
            from: collections.team._name,
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
            from: collections.lead._name,
            localField: 'shiftId',
            foreignField: '_id',
            as: 'lead',
          },
        }, {
          $lookup: {
            from: collections.shift._name,
            localField: 'shiftId',
            foreignField: '_id',
            as: 'shift',
          },
        }, {
          $lookup: {
            from: collections.project._name,
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
                  ticketId: true,
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
    name: `${prefix}.getProjectStaffing`,
    validate(projectId) { check(projectId, String) },
    run(projectId) {
      const staffing = services.stats.getDuties({ _id: projectId }, 'project', false)
      if (staffing.length === 0) {
        throw new Meteor.Error(404, 'Project not found')
      }
      return staffing[0]
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
      if (!services.auth.isLead(this.userId, teamId)) {
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
      const duties = services.stats.getDuties(query, type, true)
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
      if (!services.auth.isLead(this.userId, teamId)) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return services.stats.getTeamStats(teamId, true)
    },
  })

  new ValidatedMethod({
    name: `${prefix}.getDeptStats`,
    validate({ deptId }) {
      check(deptId, String)
    },
    run({ deptId }) {
      if (!services.auth.isLead(this.userId, deptId)) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return services.stats.getDeptStats(deptId, true)
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
      if (rota.policy === 'adminOnly' && !services.auth.isLead(this.userId, rota.parentId)) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return rota
    },
  })

  new ValidatedMethod({
    name: `${prefix}.depts.find`,
    validate({ query } = {}) {
      check(query, Match.Maybe(String))
    },
    run({ query = {} } = {}) {
      if (!services.auth.isALead()) {
        query.policy = 'public'
      }
      return collections.department.find(query).fetch()
    },
  })
}
