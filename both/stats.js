import { Meteor } from 'meteor/meteor'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line import/no-unresolved, import/extensions

import { collections } from './collections/initCollections'

const moment = extendMoment(Moment)

const uniqueVolunteers = (allSignups) =>
  new Set(allSignups?.map(signup => signup.userId)).values()

const getSignupCount = (query) => collections.signups.find(query).count()
const getVolunteerCount = (query) =>
  uniqueVolunteers(collections.signups.find(query).fetch()).length

export const projectSignupsConfirmed = (project, signupsPassed) => {
  const pdays = Array.from(moment.range(moment(project.start), moment(project.end)).by('day'))
  const dayStrings = pdays.map((m) => m.toISOString())
  const needed = new Map(dayStrings.map((day, i) => [day, project.staffing[i].min]))
  const wanted = new Map(dayStrings.map((day, i) => [day, project.staffing[i].max]))
  const confirmed = new Map(dayStrings.map((day) => [day, 0]))
  const signups = signupsPassed
    || collections.signups.find({ shiftId: project._id, status: 'confirmed' }).fetch()
  signups.forEach((signup) => {
    pdays.forEach((day) => {
      const dayString = day.toISOString()
      if (day.isBetween(signup.start, signup.end, 'days', '[]')) {
        confirmed.set(dayString, confirmed.get(dayString) + 1)
        needed.set(dayString, Math.max(needed.get(dayString) - 1, 0))
        wanted.set(dayString, Math.max(wanted.get(dayString) - 1, 0))
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

// TODO use an aggregation?
export const getDuties = (sel, type, isLead) => {
  const sort = { sort: { start: 1, priority: 1 } }
  return collections.dutiesCollections[type].find(sel, sort).map((duty) => {
    const confirmedSignups = collections.signups.find({ type, status: 'confirmed', shiftId: duty._id }, sort)
    const signups = confirmedSignups.fetch()
    const signupCount = confirmedSignups.count()
    let needed, staffing
    if (type === 'project') {
      staffing = projectSignupsConfirmed(duty, signups)
    } else if (type === 'lead') {
      needed = 1
    } else {
      needed = Math.max(0, duty.min - signupCount)
    }
    const leadOnly = {
      volunteers: uniqueVolunteers(signups),
      signups,
    }
    return {
      ...duty,
      type,
      duration: moment.duration(duty.end - duty.start).humanize(),
      confirmed: signupCount,
      needed,
      staffingStats: staffing,
      ...isLead && leadOnly,
    }
  })
}

/**
 * return a shift/task/lead document together with updated signup information
 * type: string,
 * duration: string,
 * confirmed?: int,
 * needed?: int,
 * staffingStats?: { needed: [int], wanted: [int], confirmed: [int], days: [string] },
 * volunteers: [id],
 * signups: [signups]
 * @param {Object} query Mongo query
 * @returns {Object}
 */
export const getShifts = (query, isLead) => getDuties(query, 'shift', isLead)
export const getProjects = (query, isLead) => getDuties(query, 'project', isLead)
export const getTasks = (query, isLead) => getDuties(query, 'task', isLead)
export const getLeads = (query, isLead) => getDuties(query, 'lead', isLead)

/**
 * duties => { needed: int, confirmed: int }
 */
const signupRates = (duties = []) => duties.reduce(
  (acc, duty) => ({
    needed: acc.needed + (duty.min || (duty.type === 'lead' ? 1 : 0)),
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

// query => {
//   shiftRate: { needed: int , confirmed: int},
//   leadRate: { needed: int , confirmed: int},
//   volunteerNumber: int,
//   ...team details
// }
const getTeams = (query, orgUnit = 'team') => collections[orgUnit].find(query).map((team) => {
  const leadRoles = getLeads({ parentId: team._id }, true)
  const leadIds = leadRoles.flatMap((lead) => lead.volunteers)
  return {
    shiftRate: signupRates(getShifts({ parentId: team._id }, true)),
    leadRate: signupRates(leadRoles),
    leadRoles,
    leads: Meteor.users.find({ _id: { $in: leadIds } }, {
      fields: {
        profile: true,
        ticketId: true,
        isBanned: true,
      },
    }).fetch(),
    // volunteers: getVolunteers({parentId: team._id, status: 'confirmed'}),
    volunteerNumber: getVolunteerCount({ parentId: team._id, status: 'confirmed' }),
    ...team,
  }
})

const getDepts = (query) => collections.department.find(query).map((dept) => {
  const teamsOfThisDept = getTeams({ _id: dept._id }, 'department')
    .concat(getTeams({ parentId: dept._id }))

  return {
    teamIds: teamsOfThisDept.map(team => team._id),
    teamsNumber: teamsOfThisDept.length,
    teams: teamsOfThisDept,
    volunteerNumber: teamsOfThisDept.reduce((sum, team) => sum + team.volunteerNumber, 0),
    shiftRate: sumSignupRates(teamsOfThisDept.map((team) => team.shiftRate)),
    leadRate: sumSignupRates(teamsOfThisDept.map((team) => team.leadRate)),
    ...dept,
  }
})

// All pending requests for tasks, shifts and leads
// isLead = false isn't used, so may not make much sense, it at least doesn't
// leak any sensitive info
export const getTeamStats = (teamId, isLead) => ({
  pendingRequests: getSignupCount({ parentId: teamId, status: 'pending' }),
  team: isLead && getTeams({ _id: teamId })[0],
  volunteerNumber: getVolunteerCount({ parentId: teamId, status: 'confirmed' }),
})

export const getDeptStats = (deptId, isLead) => {
  if (!isLead) {
    throw new Meteor.Error(403, 'Only able to get dept signup stats as a lead')
  }
  const dept = getDepts({ _id: deptId })[0]
  const signupQuery = { parentId: { $in: [deptId, ...dept.teamIds] }, type: 'lead', status: 'pending' }
  return {
    dept,
    pendingLeadRequests: collections.signups.find(signupQuery).fetch(),
  }
}
