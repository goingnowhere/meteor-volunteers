import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'
import { _ } from 'meteor/underscore'

import { collections } from '../collections/initCollections'
import { rotaSchema } from '../collections/duties'
import { auth } from '../utils/auth'

const moment = extendMoment(Moment)

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
    return collections.shift.insert({
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

export function createRotaMethods(eventName) {
  const prefix = `${eventName}.Volunteers`

  const methodBodies = {
    rota: {
      insert(rota) {
        const {
          shifts,
          start,
          end,
          ...details
        } = rota
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
    },
  }
  Meteor.methods({
    // eslint-disable-next-line meteor/audit-argument-checks
    [`${prefix}.rotas.insert`](rota) {
      console.log(`${prefix}.rotas.insert`, rota)
      rotaSchema.validate(rota)
      if (!auth.isLead(Meteor.userId(), [rota.parentId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return methodBodies.rota.insert(rota)
    },
    [`${prefix}.rotas.remove`](group) {
      console.log(`${prefix}.rotas.remove`, group)
      check(group, { rotaId: String, parentId: String })
      if (auth.isLead(Meteor.userId(), [group.parentId])) {
        collections.rotas.remove(group)
        return collections.shift.remove(group)
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
      collections.shift.remove({
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
        collections.shift.update({ rotaId: oldRota._id }, { $set: meta }, { multi: true })
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
          collections.shift.remove({ rotaId: oldRota._id, rotaIndex: oldIndex })
        })
      changes
        .filter(({ indexChange, timeChange, numChange }) =>
          !indexChange && !timeChange && numChange)
        .forEach(({ oldIndex, newShift: { min, max } }) => {
          collections.shift.update({ rotaId: oldRota._id, rotaIndex: oldIndex },
            { $set: { min, max } }, { multi: true })
          indexesAlreadySet.push(oldIndex)
        })
      changes
        .filter(({ indexChange }) => indexChange !== false)
        .forEach(({ oldIndex, indexChange }) => {
          collections.shift.update({ rotaId: oldRota._id, rotaIndex: oldIndex },
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

  return { methodBodies }
}
