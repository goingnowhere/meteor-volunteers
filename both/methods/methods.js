/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line import/no-unresolved, import/extensions
import SimpleSchema from 'simpl-schema'

import { collections, schemas } from '../collections/initCollections'
import { signupStatuses } from '../collections/volunteer'
import { projectSignupsConfirmed } from '../stats'
import { areShiftChangesOpen } from '../utils/event'

const share = __coffeescriptShare
const moment = extendMoment(Moment)

const findConflicts = ({
  userId,
  shiftId,
  start,
  end,
}, dutyType, parentDuty) => {
  let signupRange
  if (start && end) {
    signupRange = moment.range(start, end)
  } else if (dutyType === 'shift') {
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

const isDutyFull = ({ shiftId, start, end }, dutyType, parentDuty) => {
  if (dutyType === 'project') {
    const { wanted, days } = projectSignupsConfirmed(parentDuty)
    return wanted.some((wantedNum, i) => wantedNum < 1 && moment(days[i]).isBetween(start, end, 'days', '[]'))
  }
  const collection = collections.signupCollections[dutyType]
  const signupCount = collection.find({ shiftId, status: { $in: ['confirmed', 'pending'] } }).count()
  return signupCount >= parentDuty.max
}

const createSignupMethods = (dutyType) => {
  const signupCollection = collections.signupCollections[dutyType]
  const schema = schemas.signupSchemas[dutyType]
  Meteor.methods({
    [`${signupCollection._name}.remove`](signupId) {
      console.log(`${signupCollection._name}.remove`, signupId)
      check(signupId, String)
      const oldSignup = signupCollection.findOne(signupId)
      if (!areShiftChangesOpen(dutyType, oldSignup) && !share.isManager()) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if (share.isManagerOrLead(Meteor.userId(), [oldSignup.parentId])) {
        signupCollection.remove(signupId)
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
    [`${signupCollection._name}.setStatus`]({ id, status }) {
      console.log(`${signupCollection._name}.setStatus`, status)
      check(id, String)
      check(status, Match.OneOf(...signupStatuses))
      const oldSignup = signupCollection.findOne(id)
      if (!areShiftChangesOpen(dutyType, oldSignup) && !share.isManager()) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if (share.isManagerOrLead(Meteor.userId(), [oldSignup.parentId])) {
        signupCollection.update(id, {
          $set: {
            status,
            reviewed: oldSignup.status === 'pending' && status !== 'pending',
          },
        })
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
    [`${signupCollection._name}.update`](doc) {
      // Only used for project timing updates, can get rid of if we dump autoform for projects
      console.log(`${signupCollection._name}.update`, doc)
      if (dutyType !== 'project') {
        throw new Meteor.Error(405, 'Only possible for Project signups')
      }
      check(doc, { modifier: Object, _id: String })
      SimpleSchema.validate(doc.modifier, schema, { modifier: true })
      const oldSignup = signupCollection.findOne(doc._id)
      if (!areShiftChangesOpen(dutyType, oldSignup) && !share.isManager()) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if (share.isManagerOrLead(Meteor.userId(), [oldSignup.parentId])) {
        doc.modifier.$set.enrolled = false
        doc.modifier.$set.reviewed = (oldSignup.status === 'pending' && doc.status !== 'pending')
        signupCollection.update(doc._id, doc.modifier)
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
    },
    // this is actually an upsert
    [`${signupCollection._name}.insert`](wholeSignup) {
      console.log(`${signupCollection._name}.insert`, wholeSignup)
      check(wholeSignup, Object)
      SimpleSchema.validate(wholeSignup, schema.omit('status'))
      const signupIdentifiers = _.pick(wholeSignup, ['userId', 'shiftId', 'parentId'])
      const parentDuty = collections.dutiesCollections[dutyType].findOne(signupIdentifiers.shiftId)
      if (!areShiftChangesOpen(dutyType, wholeSignup, parentDuty) && !share.isManager()) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      const isManager = share.isManagerOrLead(this.userId, [parentDuty.parentId])
      if (parentDuty.policy === 'adminOnly' && !isManager) {
        throw new Meteor.Error(403, 'Admin only')
      }
      if ((signupIdentifiers.userId === this.userId) || isManager) {
        const status = parentDuty.policy === 'public' ? 'confirmed' : 'pending'
        const conflicts = findConflicts(wholeSignup, dutyType, parentDuty)
        if (conflicts.length !== 0) {
          throw new Meteor.Error(409, 'Double Booking', conflicts)
        }
        if (isDutyFull(wholeSignup, dutyType, parentDuty)) {
          throw new Meteor.Error(409, 'Too many signups')
        }
        const { start, end, enrolled } = wholeSignup
        const res = signupCollection.upsert(signupIdentifiers, {
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
        const existing = signupCollection.findOne(signupIdentifiers)
        return existing && existing._id
      }
      throw new Meteor.Error(403, 'Insufficient Permission')
    },
    [`${signupCollection._name}.bail`](signupIds) {
      console.log(`${signupCollection._name}.bail`, signupIds)
      check(signupIds, {
        parentId: String,
        shiftId: String,
        userId: String,
      })
      const signup = signupCollection.findOne(signupIds)
      if (!areShiftChangesOpen(dutyType, signup) && !share.isManager()) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if ((signupIds.userId === this.userId)
        || share.isManagerOrLead(this.userId, [signupIds.parentId])) {
        // multi : true just in case it is possible to singup for the same shift twice
        // this should not be possible. Failsafe !
        signupCollection.update(signupIds, {
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

  ;['shift', 'task', 'project'].forEach(type => createSignupMethods(type))
}
