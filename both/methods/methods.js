/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'
import SimpleSchema from 'simpl-schema'
import { Roles } from 'meteor/piemonkey:roles'
import { _ } from 'meteor/underscore'

import { collections, schemas } from '../collections/initCollections'
import { signupStatuses } from '../collections/volunteer'
import { projectSignupsConfirmed } from '../stats'
import { areShiftChangesOpen } from '../utils/event'
import { rotaSchema } from '../collections/duties'
import { auth } from '../utils/auth'

const share = __coffeescriptShare
const moment = extendMoment(Moment)

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

  // TODO fix this hack
  // Don't allow people to hop between projects during build without a lead doing it for them
  if (type === 'project' && projectSignups.length > 0) {
    const firstStart = moment(projectSignups[0].start)
    if (firstStart.isBefore(start)) {
      return ['You can\'t switch projects part-way through build!']
    }
  }

  const conflicts = [
    ...share.TeamShifts.find({ _id: { $in: shiftSignups } }).fetch(),
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
    const { wanted, days } = projectSignupsConfirmed(parentDuty)
    return wanted.some((wantedNum, i) => wantedNum < 1 && moment(days[i]).isBetween(start, end, 'days', '[]'))
  }
  const signupCount = collections.signups.find({ shiftId, status: { $in: ['confirmed', 'pending'] } }).count()
  return signupCount >= parentDuty.max
}

const createShifts = ({
  start,
  end,
  startTime,
  endTime,
  min,
  max,
  rotaId,
  rotaIndex,
  details,
  rangeOptions = {},
}) => {
  // Moment range goes into the future if start > end
  if (moment(start).isAfter(end)) return null
  return Array.from(moment.range(start, end).by('days', rangeOptions)).map((day) => {
    const [startHour, startMin] = startTime.split(':')
    const [endHour, endMin] = endTime.split(':')
    // this is the global timezone known by moment that we use to offset
    // the date given by the client to store it in the database as a js Date()
    // js Date() is timezone agnostic and always stored in UTC.
    // Using the method Date().toString() the local timezone (set on the server)
    // is used to print the date.
    const timezone = moment(day).format('ZZ')
    day.utcOffset(timezone)
    const shiftStart = moment(day).hour(startHour).minute(startMin).utcOffset(timezone, true)
    const shiftEnd = moment(day).hour(endHour).minute(endMin).utcOffset(timezone, true)
    // Deal with day wrap-around
    if (shiftEnd.isBefore(shiftStart)) {
      shiftEnd.add(1, 'day')
    }
    return share.TeamShifts.insert({
      ...details,
      min,
      max,
      start: shiftStart.toDate(),
      end: shiftEnd.toDate(),
      rotaId,
      rotaIndex,
    })
  })
}

export const initMethods = (eventName) => {
  share.initMethods(eventName)
  const prefix = `${eventName}.Volunteers`

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
    if (auth.isLead(Meteor.userId(), [oldSignup.parentId])) {
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
      if (auth.isLead(Meteor.userId(), [oldSignup.parentId])) {
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
      SimpleSchema.validate(doc.modifier, schemas.signups, { modifier: true })
      const oldSignup = collections.signups.findOne(doc._id)
      if (oldSignup.type !== 'project') {
        throw new Meteor.Error(405, 'Only possible for Project signups')
      }
      const isLead = auth.isLead(Meteor.userId(), [oldSignup.parentId])
      if (!areShiftChangesOpen(oldSignup) && !isLead) {
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
    },
    // this is actually an upsert
    [`${prefix}.signups.insert`](wholeSignup) {
      console.log(`${prefix}.signups.insert`, wholeSignup)
      check(wholeSignup, Object)
      SimpleSchema.validate(wholeSignup, schemas.signups.omit('status'))
      const signupIdentifiers = _.pick(wholeSignup, ['userId', 'shiftId', 'parentId'])
      const parentDuty = collections.dutiesCollections[wholeSignup.type]
        .findOne(signupIdentifiers.shiftId)
      if (!parentDuty && Meteor.isClient) {
        // Calling as a server method so stub has nothing to do
        return null
      }
      const isLead = auth.isLead(this.userId, [parentDuty.parentId])
      if (!areShiftChangesOpen(wholeSignup, parentDuty) && !isLead) {
        throw new Meteor.Error(403, 'Too late to change this shift! Contact your lead')
      }
      if (parentDuty.policy === 'adminOnly' && !isLead) {
        throw new Meteor.Error(403, 'Admin only')
      }
      if ((signupIdentifiers.userId === this.userId) || isLead) {
        // Leads cannot be public so no special handling of roles needed in this method
        const status = parentDuty.policy === 'public' ? 'confirmed' : 'pending'
        const [failReason, conflicts] = findConflicts(wholeSignup, parentDuty)
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
        const res = collections.signups.upsert(signupIdentifiers, {
          $set: {
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
      const isLead = auth.isLead(this.userId, [signupIds.parentId])
      if (!areShiftChangesOpen(signup) && !isLead) {
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

  Meteor.methods({
    // eslint-disable-next-line meteor/audit-argument-checks
    [`${prefix}.rotas.insert`](rota) {
      console.log(`${prefix}.rotas.insert`, rota)
      rotaSchema.validate(rota)
      const {
        shifts,
        start,
        end,
        parentId,
      } = rota
      const details = _.omit(rota, 'shifts', 'start', 'end')
      if (!auth.isLead(Meteor.userId(), [parentId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      // store rota
      const rotaId = collections.rotas.insert(rota)
      // generate and store shifts
      return shifts.map((shiftSpecifics, rotaIndex) =>
        createShifts({
          ...shiftSpecifics,
          start,
          end,
          rotaId,
          rotaIndex,
          details,
        }))
    },
    [`${prefix}.rotas.remove`](group) {
      console.log(`${prefix}.rotas.remove`, group)
      check(group, { rotaId: String, parentId: String })
      if (auth.isLead(Meteor.userId(), [group.parentId])) {
        collections.rotas.remove(group)
        return share.TeamShifts.remove(group)
      }
      throw new Meteor.Error(403, 'Insufficient Permission')
    },
    // eslint-disable-next-line meteor/audit-argument-checks
    [`${prefix}.rotas.update`]({ modifier, ...query }) {
      console.log(`${prefix}.rotas.update`, query, modifier)
      // TODO Instead of using autoform, report changes and only make them if confirmed
      if (modifier.$set && modifier.$set.shifts) {
        // Do we really need to filter out nulls?
        modifier.$set.shifts = modifier.$set.shifts.filter(Boolean)
      }
      rotaSchema.validate(modifier, { modifier: true })
      const oldRota = collections.rotas.findOne(query)
      // Should be a server method?
      if (!oldRota && Meteor.isClient) return null
      if (!auth.isLead(Meteor.userId(), [oldRota.parentId])
        || modifier.$set.parentId !== oldRota.parentId) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      console.log('Updating rota (debug):', query, modifier, modifier.$set.shifts, oldRota)

      // Delete any shifts outside of the new rota days
      const {
        start,
        end,
        shifts,
        ...meta
      } = modifier.$set
      // 'end' is /start/ of last day in event local timezone
      const lastRotaDayEnd = moment(end).add(1, 'day')
      share.TeamShifts.remove({
        rotaId: oldRota._id,
        $or: [
          { start: { $lt: start } },
          // shifts can overflow to tomorrow so 'last day' constrains the shift starts
          { start: { $gte: lastRotaDayEnd.toDate() } },
        ],
      })
      // TODO delete signups

      // Apply any changes to the meta information
      if (Object.entries(meta).some(([key, value]) => oldRota[key] !== value)) {
        share.TeamShifts.update({ rotaId: oldRota._id }, { $set: meta }, { multi: true })
      }

      // Go through oldRota.shifts to find which have changed
      const changes = oldRota.shifts.map((oldShift, oldIndex) => {
        const newIndex = shifts.findIndex((shift) => _.isEqual(shift, oldShift))
        // Assume index is the same if there isn't an exact match. Need to improve when re-writing
        const newShift = shifts[oldIndex]
        const timeChange = newShift.startTime !== oldShift.startTime
          || newShift.endTime !== oldShift.endTime
        return {
          indexChange: (newIndex !== -1 && newIndex !== oldIndex) ? newIndex : false,
          numChange: newShift.min !== oldShift.min || newShift.max !== oldShift.max,
          timeChange,
          oldIndex,
          oldShift,
          newShift,
        }
      })
      // Update any we can and remove those with time changes
      const indexesAlreadySet = changes
        .filter((change) => !change.indexChange && !change.numChange && !change.timeChange)
        .map(({ oldIndex }) => oldIndex)
      changes
        .filter(({ indexChange, timeChange }) => (indexChange === false) && timeChange)
        .forEach(({ oldIndex }) => {
          share.TeamShifts.remove({ rotaId: oldRota._id, rotaIndex: oldIndex })
        })
      changes
        .filter(({ indexChange, timeChange, numChange }) =>
          !indexChange && !timeChange && numChange)
        .forEach(({ oldIndex, newShift: { min, max } }) => {
          share.TeamShifts.update({ rotaId: oldRota._id, rotaIndex: oldIndex },
            { $set: { min, max } }, { multi: true })
          indexesAlreadySet.push(oldIndex)
        })
      changes
        .filter(({ indexChange }) => indexChange !== false)
        .forEach(({ oldIndex, indexChange }) => {
          share.TeamShifts.update({ rotaId: oldRota._id, rotaIndex: oldIndex },
            { $set: { rotaIndex: indexChange } }, { multi: true })
          indexesAlreadySet.push(indexChange)
        })

      // Create any new shifts that don't exist already in the old rota days
      modifier.$set.shifts.forEach((shift, index) => {
        if (indexesAlreadySet.includes(index)) return
        createShifts({
          ...shift,
          start: oldRota.start,
          end: oldRota.end,
          rotaId: oldRota._id,
          rotaIndex: index,
          details: _.omit(modifier.$set, 'shifts', 'start', 'end'),
        })
      })

      // Create any shifts for days outside the old rota days
      if (moment(start).isBefore(oldRota.start)) {
        modifier.$set.shifts.forEach((shift, index) => {
          createShifts({
            ...shift,
            start,
            end: oldRota.start,
            rotaId: oldRota._id,
            rotaIndex: index,
            details: _.omit(modifier.$set, 'shifts', 'start', 'end'),
            rangeOptions: { excludeEnd: true },
          })
        })
      }
      if (moment(oldRota.end).isBefore(end)) {
        modifier.$set.shifts.forEach((shift, index) => {
          createShifts({
            ...shift,
            // Workaround moment-range poor edge-case handling
            start: moment(oldRota.end).add(1, 'day').toDate(),
            end,
            rotaId: oldRota._id,
            rotaIndex: index,
            details: _.omit(modifier.$set, 'shifts', 'start', 'end'),
            rangeOptions: { excludeStart: true },
          })
        })
      }

      // ...and finally we can update the rota
      return collections.rotas.update(query, modifier)
    },
  })
}
