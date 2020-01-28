/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

import { collections } from '../both/collections/initCollections'

const share = __coffeescriptShare

const moment = extendMoment(Moment)

share.initServerMethods = (eventName) => {
  const prefix = `${eventName}.Volunteers`
  const getProjectStaffing = new ValidatedMethod({
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
          const thisday = signups.filter(signup => (day.isBetween(signup.start, signup.end, 'days', '[]')))
          return thisday.length
        })
        return confirmed
      }
      throw new Meteor.Error('InternalError', 'Project not found')
    },
  })

  Meteor.methods({
    'signups.list.manager'(type) { //eslint-disable-line
      if (!share.isManager()) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collections.signups.aggregate([
        {
          $match: { type, status: 'pending' },
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
            as: 'duty',
          },
        }, {
          $unwind: { path: '$duty' },
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

  return getProjectStaffing
}
