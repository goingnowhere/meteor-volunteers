import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

import { dutyPriorityScore, userPrefsMatch } from '../collections/utils'

export function initDutiesMethods(volunteersClass) {
  const { collections, services: { auth }, settings } = volunteersClass

  function createMethod(collection) {
    const collectionName = collection._name
    Meteor.methods({
      [`${collectionName}.remove`](id) {
        console.log(`${collectionName}.remove`, id)
        check(id, String)
        const doc = collection.findOne(id)
        if (!auth.isLead(Meteor.userId(), doc.parentId)) {
          throw new Meteor.Error(403, 'Insufficient Permission')
        }
        collection.remove(id)
        collections.signups.update({ shiftId: id }, { $set: { status: 'cancelled' } })
      },
      [`${collectionName}.insert`](doc) {
        console.log([`${collectionName}.insert`, doc])
        check(doc, Object)
        collection.simpleSchema().validate(doc)
        if (!auth.isLead(Meteor.userId(), doc.parentId)) {
          throw new Meteor.Error(403, 'Insufficient Permission')
        }
        return collection.insert(doc)
      },
      [`${collectionName}.update`](doc) {
        console.log([`${collectionName}.update`, doc._id, doc.modifier])
        check(doc, Object)
        collection.simpleSchema().validate(doc.modifier, { modifier: true })
        const olddoc = collection.findOne(doc._id)
        if (!this.isSimulation && !auth.isLead(Meteor.userId(), olddoc.parentId)) {
          throw new Meteor.Error(403, 'Insufficient Permission')
        }
        return collection.update(doc._id, doc.modifier)
      },
    })
  }

  // Actually create the methods (nothing to return as they're not 'ValidatedMethod's)
  Object.values(collections.dutiesCollections).forEach(dutyColl => {
    createMethod(dutyColl)
  })

  return {
    listOpenShifts: new ValidatedMethod({
      name: 'shifts.open.list',
      validate: ({ type }) => check(type, Match.OneOf('build', 'strike', 'build-strike')),
      run({
        type,
      }) {
        // Aggregate is only available on the server
        if (!Meteor.isServer) {
          return []
        }
        const eventStart = settings.eventPeriod?.start
        const eventEnd = settings.eventPeriod?.end
        return collections.project.aggregate([
          {
            $match: {
              policy: { $in: ['public', 'requireApproval'] },
              ...type === 'build' && eventStart && { start: { $lt: eventStart } },
              ...type === 'strike' && eventEnd && { end: { $gt: eventEnd } },
            },
          },
          // Get volunteer form to have user preferences
          {
            $lookup: {
              from: collections.volunteerForm._name,
              let: { userId: this.userId },
              pipeline: [
                {
                  $match: { $expr: { $eq: ['$userId', '$$userId'] } },
                },
                {
                  $project: { skills: true, quirks: true },
                },
              ],
              as: 'prefs',
            },
          },
          {
            $unwind: { path: '$prefs' },
          },
          // Get team for skills and quirk info
          {
            $lookup: {
              from: collections.team._name,
              localField: 'parentId',
              foreignField: '_id',
              as: 'team',
            },
          },
          {
            $unwind: { path: '$team' },
          },
          // Get confirmed signups to judge staffing levels
          {
            $lookup: {
              from: collections.signups._name,
              let: { shiftId: '$_id' },
              pipeline: [
                { $match: { $expr: { $eq: ['$$shiftId', '$shiftId'] }, status: 'confirmed' } },
                {
                  $project: {
                    days: {
                      // If moving to later than mongo 5.0 can use dateDiff
                      $add: [{ $divide: [{ $subtract: ['$end', '$start'] }, 1000 * 60 * 60 * 24] }, 1],
                    },
                  },
                },
              ],
              as: 'signups',
            },
          },
          {
            $addFields: {
              // A literal to indicate what type of 'duty'
              type: 'project',
              volDays: { $sum: '$signups.days' },
              minStaffing: { $sum: '$staffing.min' },
              maxStaffing: { $sum: '$staffing.max' },
              quirks: '$team.quirks',
              skills: '$team.skills',
            },
          },
          {
            $addFields: {
              // How many skills or quirks match the user's
              preferenceScore: userPrefsMatch('$prefs.skills', '$prefs.quirks'),
              priorityScore: dutyPriorityScore,
              minRemaining: { $max: [0, { $subtract: ['$minStaffing', '$volDays'] }] },
              maxRemaining: { $max: [0, { $subtract: ['$maxStaffing', '$volDays'] }] },
            },
          },
          {
            $addFields: {
              score: {
                $add: [
                  { $multiply: ['$maxRemaining', { $add: [1, '$preferenceScore'] }] },
                  { $multiply: ['$minRemaining', '$priorityScore', { $add: [1, '$preferenceScore'] }] },
                ],
              },
            },
          },
          {
            $sort: { score: -1 },
          },
        ])
      },
    }),
  }
}
