/* globals __coffeescriptShare */
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line import/no-unresolved, import/extensions
import { _ } from 'meteor/underscore'

import { collections } from './collections/initCollections'

const moment = extendMoment(Moment)

const uniqueVolunteers = allSignups => (
  !allSignups ? []
    : _.chain(allSignups)
      .pluck('userId')
      .uniq()
      .value())

// TODO use an aggregation?
const getDuties = (sel, type) => {
  const sort = { sort: { start: 1, priority: 1 } }
  return collections.dutiesCollections[type].find(sel, sort).map((duty) => {
    const confirmedSignups = collections.signups.find({ type, status: 'confirmed', shiftId: duty._id }, sort)
    const signups = confirmedSignups.fetch()
    const signupCount = confirmedSignups.count()
    return {
      ...duty,
      type,
      duration: moment.duration(duty.end - duty.start).humanize(),
      confirmed: signupCount,
      needed: Math.max(0, duty.min - signupCount),
      volunteers: uniqueVolunteers(signups),
      signups,
    }
  })
}

/**
 * return a shift/task/lead document together with updated signup information
 * type: string,
 * duration: string,
 * confirmed: int,
 * needed: int,
 * volunteers: [id],
 * signups: [signups]
 * @param {Object} query Mongo query
 * @returns {Object}
 */
export const getShifts = query => getDuties(query, 'shift')
export const getProjects = query => getDuties(query, 'project')
export const getTasks = query => getDuties(query, 'task')
export const getLeads = query => getDuties(query, 'lead')

const getSignupCount = query => collections.signups.find(query).count()
const getVolunteerCount = query => uniqueVolunteers(collections.signups.find(query).fetch()).length

/**
 * duties => { needed: int, confirmed: int }
 */
const signupRates = (duties = []) => duties.reduce(
  (acc, duty) => ({
    needed: acc.needed + (duty.min || 0),
    confirmed: acc.confirmed + (duty.confirmed || 0),
  }),
  { needed: 0, confirmed: 0 },
)

const sumSignupRates = (rates = []) => rates.reduce(
  (acc, rate) => ({
    needed: acc.needed + rate.needed,
    confirmed: acc.confirmed + rate.confirmed,
  }),
  { needed: 0, confirmed: 0 },
)

const share = __coffeescriptShare

// query => {
//   shiftRate: { needed: int , confirmed: int},
//   leadRate: { needed: int , confirmed: int},
//   volunteerNumber: int,
//   ...team details
// }
const getTeams = query => share.Team.find(query).map(team => ({
  shiftRate: signupRates(getShifts({ parentId: team._id })),
  leadRate: signupRates(getLeads({ parentId: team._id })),
  // volunteers: getVolunteers({parentId: team._id, status: 'confirmed'}),
  volunteerNumber: getVolunteerCount({ parentId: team._id, status: 'confirmed' }),
  ...team,
}))

const getDepts = query => share.Department.find(query).map((dept) => {
  const teamsOfThisDept = getTeams({ parentId: dept._id })

  return {
    teamIds: _.pluck(teamsOfThisDept, '_id'),
    teamsNumber: teamsOfThisDept.length,
    volunteerNumber: teamsOfThisDept.reduce((sum, team) => sum + team.volunteerNumber, 0),
    shiftRate: sumSignupRates(teamsOfThisDept.map(team => team.shiftRate)),
    leadRate: sumSignupRates(teamsOfThisDept.map(team => team.leadRate)),
  }
})

export const teamStats = (parentId) => {
  // All pending requests for tasks, shifts and leads
  const stats = {
    pendingRequests: getSignupCount({ parentId, status: 'pending' }),
    team: getTeams({ _id: parentId })[0],
    volunteerNumber: getVolunteerCount({ parentId, status: 'confirmed' }),
  }
  share.UnitAggregation.upsert(parentId, { $set: stats })
  return stats
}

export const deptStats = (parentId) => {
  const dept = getDepts({ _id: parentId })[0]
  const signupQuery = { parentId: { $in: dept.teamIds }, status: 'pending' }
  const pendingLeadRequests = collections.signups.find(signupQuery).count()
  const stats = { dept, pendingLeadRequests }
  share.UnitAggregation.upsert(parentId, { $set: stats })
  return stats
}

export const projectSignupsConfirmed = (p) => {
  const pdays = Array.from(moment.range(moment(p.start), moment(p.end)).by('day'))
  const dayStrings = pdays.map(m => m.toISOString())
  const needed = new Map(dayStrings.map((day, i) => [day, p.staffing[i].min]))
  const wanted = new Map(dayStrings.map((day, i) => [day, p.staffing[i].max]))
  const confirmed = new Map(dayStrings.map(day => [day, 0]))
  const signups = collections.signups.find({ shiftId: p._id, status: 'confirmed' }).fetch()
  signups.forEach((signup) => {
    pdays.forEach((day) => {
      const dayString = day.toISOString()
      if (day.isBetween(signup.start, signup.end, 'days', '[]')) {
        confirmed.set(dayString, confirmed.get(dayString) + 1)
        needed.set(dayString, needed.get(dayString) - 1)
        wanted.set(dayString, wanted.get(dayString) - 1)
      }
    })
  })
  return {
    needed: Array.from(needed.values()),
    wanted: Array.from(wanted.values()),
    confirmed: Array.from(confirmed.values()),
    days: dayStrings,
  }
}
