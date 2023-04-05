import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'
import SimpleSchema from 'simpl-schema'
import { Roles } from 'meteor/alanning:roles'
import { _ } from 'meteor/underscore'

import { signupStatuses } from '../collections/schemas/volunteer'

const moment = extendMoment(Moment)

export const initSignupMethods = (volunteersClass) => {
  const {
    collections, eventName, schemas, services,
  } = volunteersClass
  const prefix = `${eventName}.Volunteers`

  const findConflicts = ({
    userId,
    shiftId,
    type,
    start,
    end,
  }, parentDuty) => {
    let signupRange
    if (start && end) {
      signupRange = moment.range(start, end)
    } else if (type === 'shift') {
      signupRange = moment.range(parentDuty.start, parentDuty.end)
    } else {
      return []
    }
    const signups = collections.signups.find({
    // it's a double booking only if it is a different shift
      shiftId: { $ne: shiftId },
      userId,
      status: { $in: ['confirmed', 'pending'] },
    }, { sort: { start: 1 } }).fetch()
    const shiftSignups = signups.filter((signup) => signup.type === 'shift').map((signup) => signup.shiftId)
    const projectSignups = signups.filter((signup) => signup.type === 'project')

    const conflicts = [
      ...collections.shift.find({ _id: { $in: shiftSignups } }).fetch(),
      ...projectSignups,
    ].filter((shift) => shift && signupRange.overlaps(moment.range(shift.start, shift.end)))
    if (conflicts.length > 0) {
      return ['Double Booking', conflicts]
    }
    return []
  }

  const isDutyFull = ({
    shiftId,
    type,
    start,
    end,
  }, parentDuty) => {
    if (type === 'project') {
      const { needed, wanted, days } = services.stats.projectSignupsConfirmed(parentDuty)
      return wanted.some((wantedNum, i) =>
        wantedNum < 1 && needed[i] < 1
        && moment(days[i]).isBetween(start, end, 'days', '[]'))
    }
    const signupCount = collections.signups.find({ shiftId, status: { $in: ['confirmed', 'pending'] } }).count()
    if (type === 'lead') {
      return signupCount >= 1
    }
    return signupCount >= parentDuty.max
  }

  // Status can be either confirmed or refused
  const createSignupStatusMethod = (status) => (signupId) => {
    console.log(`${prefix}.signups.set.${status}`, signupId)
    check(signupId, String)
    check(status, Match.OneOf(...signupStatuses))
    const oldSignup = collections.signups.findOne(signupId)
    if (!oldSignup && Meteor.isClient) {
      // Calling as a server method so stub has nothing to do
      return null
    }
    if (services.auth.isLead(Meteor.userId(), oldSignup.parentId)) {
      collections.signups.update(signupId, {
        $set: {
          status,
          reviewed: true,
        },
      }, (err) => {
        if (err) {
          console.error('Error updating signup status', err)
          throw new Meteor.Error(500, 'Cannot Update')
        }
        if (oldSignup.type === 'lead' && Meteor.isServer) {
          if (status === 'confirmed') {
            Roles.addUsersToRoles(oldSignup.userId, oldSignup.parentId, eventName)
          } else if (status === 'refused') {
            Roles.removeUsersFromRoles(oldSignup.userId, oldSignup.parentId, eventName)
          }
        }
      })
      return null
    }
    throw new Meteor.Error(403, 'Insufficient Permission')
  }

  Meteor.methods({
    [`${prefix}.signups.remove`](signupId) {
      console.log(`${prefix}.signups.remove`, signupId)
      check(signupId, String)
      const oldSignup = collections.signups.findOne(signupId)
      if (!oldSignup && Meteor.isClient) {
        // Calling as a server method so stub has nothing to do
        return null
      }
      if (services.auth.isLead(Meteor.userId(), oldSignup.parentId)) {
        return collections.signups.remove(signupId, (err) => {
          if (err) {
            console.error('Error when removing signup', err)
            throw new Meteor.Error(500, 'Cannot Remove')
          }
          if (oldSignup.type === 'lead' && Meteor.isServer) {
            Roles.removeUsersFromRoles(oldSignup.userId, oldSignup.parentId, eventName)
          }
        })
      }
      throw new Meteor.Error(403, 'Insufficient Permission')
    },
    [`${prefix}.signups.confirm`]: createSignupStatusMethod('confirmed'),
    [`${prefix}.signups.refuse`]: createSignupStatusMethod('refused'),
    [`${prefix}.signups.update`](doc) {
      // Only used for project timing updates, can get rid of if we dump autoform for projects
      console.log(`${prefix}.signups.update`, doc)
      check(doc, { modifier: Object, _id: String })
      SimpleSchema.validate(doc.modifier, schemas.signup, { modifier: true })
      const oldSignup = collections.signups.findOne(doc._id)
      if (oldSignup.type !== 'project') {
        throw new Meteor.Error(405, 'Only possible for Project signups')
      }
      const isLead = services.auth.isLead(Meteor.userId(), oldSignup.parentId)
      if (!services.event.areShiftChangesOpen(oldSignup) && !isLead) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if (isLead) {
        doc.modifier.$set.enrolled = true
        // This logic probably needs review but currently this isn't used to approve
        doc.modifier.$set.reviewed = (oldSignup.status === 'pending' && doc.status !== 'pending')
        collections.signups.update(doc._id, doc.modifier)
      } else if (oldSignup.userId === Meteor.userId()) {
        const parentDuty = collections.dutiesCollections[oldSignup.type]
          .findOne({ _id: oldSignup.shiftId })
        if (!parentDuty && Meteor.isClient) {
        // Calling as a server method so stub has nothing to do
          return null
        }
        doc.modifier.$set = {
          ...doc.modifier.$set,
          status: parentDuty.policy === 'public' ? 'confirmed' : 'pending',
          reviewed: false,
          enrolled: false,
        }
        collections.signups.update(doc._id, doc.modifier)
      } else {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return true
    },
    // this is actually an upsert
    [`${prefix}.signups.insert`](wholeSignup) {
      console.log(`${prefix}.signups.insert`, wholeSignup)
      check(wholeSignup, Object)
      SimpleSchema.validate(wholeSignup, schemas.signup.omit('status'))
      const signupIdentifiers = _.pick(wholeSignup, ['userId', 'shiftId', 'parentId'])
      const parentDuty = collections.dutiesCollections[wholeSignup.type]
        .findOne(signupIdentifiers.shiftId)
      if (!parentDuty && Meteor.isClient) {
        // Calling as a server method so stub has nothing to do
        return null
      }
      const isLead = services.auth.isLead(this.userId, parentDuty.parentId)
      if (!services.event.areShiftChangesOpen(wholeSignup, parentDuty) && !isLead) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if (parentDuty.policy === 'adminOnly' && !isLead) {
        throw new Meteor.Error(403, 'Admin only')
      }
      if ((signupIdentifiers.userId === this.userId) || isLead) {
        // Leads cannot be public so no special handling of roles needed in this method
        const status = parentDuty.policy === 'public' ? 'confirmed' : 'pending'
        const [failReason, conflicts] = findConflicts(collections, wholeSignup, parentDuty)
        if (failReason) {
          throw new Meteor.Error(409, failReason, conflicts)
        }
        if (isDutyFull(wholeSignup, parentDuty)) {
          throw new Meteor.Error(409, 'Too many signups')
        }
        const {
          type,
          start,
          end,
          enrolled,
        } = wholeSignup
        if (type === 'project' && (
          moment(start).isBefore(parentDuty.start)
          || moment(end).isAfter(parentDuty.end)
        )) {
          throw new Meteor.Error(400, 'Start and end need to be within the project dates')
        }
        const res = collections.signups.upsert(signupIdentifiers, {
          $set: {
            ...signupIdentifiers,
            type,
            status,
            start,
            end,
            enrolled,
            notification: false,
            createdAt: new Date(),
          },
        })
        if (res && res.insertedId) {
          return res.insertedId
        }
        const existing = collections.signups.findOne(signupIdentifiers)
        return existing && existing._id
      }
      throw new Meteor.Error(403, 'Insufficient Permission')
    },
    [`${prefix}.signups.bail`](signupIds) {
      console.log(`${prefix}.signups.bail`, signupIds)
      check(signupIds, {
        parentId: String,
        shiftId: String,
        userId: String,
      })
      const signup = collections.signups.findOne(signupIds)
      const isLead = services.auth.isLead(this.userId, signupIds.parentId)
      if (!services.event.areShiftChangesOpen(signup) && !isLead) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if ((signupIds.userId === this.userId) || isLead) {
        // multi : true just in case it is possible to singup for the same shift twice
        // this should not be possible. Failsafe !
        return collections.signups.update(signupIds, {
          $set: {
            status: 'bailed',
          },
        }, (err) => {
          if (err) {
            console.error('Error when bailing', err)
            throw new Meteor.Error(500, 'Cannot Update')
          }
          if (signup.type === 'lead' && signup.status === 'confirmed' && Meteor.isServer) {
            Roles.removeUsersFromRoles(signup.userId, signup.parentId, eventName)
          }
        })
      }
      throw new Meteor.Error(403, 'Insufficient Permission')
    },
  })
}
