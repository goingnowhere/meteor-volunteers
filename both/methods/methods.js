/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line import/no-unresolved, import/extensions
import SimpleSchema from 'simpl-schema'

import { signupStatuses } from '../collections/volunteer'
import { projectSignupsConfirmed } from '../stats'

const share = __coffeescriptShare
const moment = extendMoment(Moment)

const findConflicts = ({
  userId,
  shiftId,
  start,
  end,
}, collectionKey, parentDuty) => {
  let signupRange
  if (start && end) {
    signupRange = moment.range(start, end)
  } else if (collectionKey === 'ShiftSignups') {
    signupRange = moment.range(parentDuty.start, parentDuty.end)
  } else {
    return []
  }
  const shiftSignups = share.ShiftSignups.find({
    // it's a double booking only if it is a different shift
    shiftId: { $ne: shiftId },
    userId,
    status: { $in: ['confirmed', 'pending'] },
  }, { shiftId: true }).map(signup => signup.shiftId)
  const projectSignups = share.ProjectSignups.find({
    // it's a double booking only if it is a different shift
    shiftId: { $ne: shiftId },
    userId,
    status: { $in: ['confirmed', 'pending'] },
  }).fetch()
  return [
    ...share.TeamShifts.find({ _id: { $in: shiftSignups } }).fetch(),
    ...projectSignups,
  ].filter(shift => shift && signupRange.overlaps(moment.range(shift.start, shift.end)))
}

const isDutyFull = ({ shiftId, start, end }, collectionKey, parentDuty) => {
  const collection = share[collectionKey]
  if (collectionKey === 'ProjectSignups') {
    const { wanted, days } = projectSignupsConfirmed(parentDuty)
    return wanted.some((wantedNum, i) => wantedNum < 1 && moment(days[i]).isBetween(start, end, 'days', '[]'))
  }
  const signupCount = collection.find({ shiftId, status: { $in: ['confirmed', 'pending'] } }).count()
  return signupCount >= parentDuty.max
}

const createSignupMethods = (collectionKey, parentCollection) => {
  const collection = share[collectionKey]
  const schema = share.Schemas[collectionKey]
  const collectionName = collection._name
  Meteor.methods({
    [`${collectionName}.remove`](shiftId) {
      console.log(`${collectionName}.remove`, shiftId)
      check(shiftId, String)
      const olddoc = collection.findOne(shiftId)
      if (share.isManagerOrLead(Meteor.userId(), [olddoc.parentId])) {
        collection.remove(shiftId)
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
    [`${collectionName}.setStatus`]({ id, status }) {
      console.log(`${collectionName}.setStatus`, status)
      check(id, String)
      check(status, Match.OneOf(...signupStatuses))
      const oldSignup = collection.findOne(id)
      if (share.isManagerOrLead(Meteor.userId(), [oldSignup.parentId])) {
        collection.update(id, {
          $set: {
            status,
            reviewed: oldSignup.status === 'pending' && status !== 'pending',
          },
        })
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
    [`${collectionName}.update`](doc) {
      // Only used for project timing updates, can get rid of if we dump autoform for projects
      console.log(`${collectionName}.update`, doc)
      if (collectionKey !== 'ProjectSignups') {
        throw new Meteor.Error(405, 'Only possible for Project signups')
      }
      check(doc, { modifier: Object, _id: String })
      SimpleSchema.validate(doc.modifier, schema, { modifier: true })
      const olddoc = collection.findOne(doc._id)
      if (share.isManagerOrLead(Meteor.userId(), [olddoc.parentId])) {
        doc.modifier.$set.enrolled = false
        doc.modifier.$set.reviewed = (olddoc.status === 'pending' && doc.status !== 'pending')
        collection.update(doc._id, doc.modifier)
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
    // this is actually an upsert
    [`${collectionName}.insert`](wholeSignup) {
      console.log(`${collectionName}.insert`, wholeSignup)
      check(wholeSignup, Object)
      SimpleSchema.validate(wholeSignup, schema.omit('status'))
      const signupIdentifiers = _.pick(wholeSignup, ['userId', 'shiftId', 'parentId'])
      const parentDuty = parentCollection.findOne(signupIdentifiers.shiftId)
      const isManager = share.isManagerOrLead(this.userId, [parentDuty.parentId])
      if (parentDuty.policy === 'adminOnly' && !isManager) {
        throw new Meteor.Error(403, 'Admin only')
      }
      if ((signupIdentifiers.userId === this.userId) || isManager) {
        const status = parentDuty.policy === 'public' ? 'confirmed' : 'pending'
        const conflicts = findConflicts(wholeSignup, collectionKey, parentDuty)
        if (conflicts.length !== 0) {
          throw new Meteor.Error(409, 'Double Booking', conflicts)
        }
        if (isDutyFull(wholeSignup, collectionKey, parentDuty)) {
          throw new Meteor.Error(409, 'Too many signups')
        }
        const { start, end, enrolled } = wholeSignup
        const res = collection.upsert(signupIdentifiers, {
          $set: {
            status,
            start,
            end,
            enrolled,
            notification: false,
          },
        })
        if (res && res.insertedId) {
          return res.insertedId
        }
        const existing = collection.findOne(signupIdentifiers)
        return existing && existing._id
      }
      throw new Meteor.Error(403, 'Insufficient Permission')
    },
    [`${collectionName}.bail`](signupIds) {
      console.log(`${collectionName}.bail`, signupIds)
      check(signupIds, {
        parentId: String,
        shiftId: String,
        userId: String,
      })
      if ((signupIds.userId === this.userId)
        || share.isManagerOrLead(this.userId, [signupIds.parentId])) {
        // multi : true just in case it is possible to singup for the same shift twice
        // this should not be possible. Failsafe !
        collection.update(signupIds, {
          $set: {
            status: 'bailed',
          },
        }, { multi: true })
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
  })
}

export const initMethods = (eventName) => {
  share.initMethods(eventName)

  createSignupMethods('ShiftSignups', share.TeamShifts)
  createSignupMethods('TaskSignups', share.TeamTasks)
  createSignupMethods('ProjectSignups', share.Projects)
}
