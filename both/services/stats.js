import { Meteor } from 'meteor/meteor'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

const moment = extendMoment(Moment)

const uniqueVolunteers = (allSignups) =>
  [...new Set(allSignups?.map(signup => signup.userId)).values()]

export const initStatsService = (volunteersClass) => {
  const { collections } = volunteersClass
  const service = {}

  const getSignupCount = (query) => collections.signups.find(query).count()
  const getVolunteerCount = (query) =>
    uniqueVolunteers(collections.signups.find(query).fetch()).length

  service.projectSignupsConfirmed = (project, signupsPassed, days) => {
    const pdays = Array.from(moment.range(moment(project.start), moment(project.end))
      .by('day'))
    const displayDays = days ?? pdays
    const dayStrings = displayDays.map((m) => m.toISOString())

    const staffing = new Map(pdays.map((day, i) => [day.toISOString(), project.staffing[i]]))
    const needed = new Map(dayStrings.map((day) => [day, staffing.get(day)?.min ?? 0]))
    const wanted = new Map(dayStrings.map((day) =>
      [day, (staffing.get(day)?.max ?? 0) - (staffing.get(day)?.min ?? 0)]))
    const confirmed = new Map(dayStrings.map((day) => [day, 0]))
    const signups = signupsPassed
      || collections.signups.find({ shiftId: project._id, status: 'confirmed' }).fetch()
    signups.forEach((signup) => {
      displayDays.forEach((day) => {
        const dayString = day.toISOString()
        if (day.isBetween(signup.start, signup.end, 'days', '[]')) {
          confirmed.set(dayString, confirmed.get(dayString) + 1)
          if (needed.get(dayString)) {
            needed.set(dayString, Math.max(needed.get(dayString) - 1, 0))
          } else {
            wanted.set(dayString, Math.max(wanted.get(dayString) - 1, 0))
          }
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
  service.getDuties = (sel, type, isLead) => {
    const sort = { sort: { start: 1, priority: 1 } }
    return collections.dutiesCollections[type].find(sel, sort).map((duty) => {
      const confirmedSignups = collections.signups.find({ type, status: 'confirmed', shiftId: duty._id }, sort)
      const signups = confirmedSignups.fetch()
      const signupCount = confirmedSignups.count()
      let needed, staffing
      if (type === 'project') {
        staffing = service.projectSignupsConfirmed(duty, signups)
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
  service.getShifts = (query, isLead) => service.getDuties(query, 'shift', isLead)
  service.getProjects = (query, isLead) => service.getDuties(query, 'project', isLead)
  service.getTasks = (query, isLead) => service.getDuties(query, 'task', isLead)
  service.getLeads = (query, isLead) => service.getDuties(query, 'lead', isLead)

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
  /**
   * Lead only
   */
  const getTeams = (query, orgUnit = 'team') => collections[orgUnit].find(query).map((team) => {
    const leadRoles = service.getLeads({ parentId: team._id }, true)
    const leadIds = leadRoles.flatMap((lead) => lead.volunteers)
    return {
      shiftRate: signupRates(service.getShifts({ parentId: team._id }, true)),
      leadRate: signupRates(leadRoles),
      leadRoles,
      leads: Meteor.users.find({ _id: { $in: leadIds } }, {
        fields: {
          emails: true,
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

  /**
   * Lead only
   */
  const getDepts = (query) => collections.department.find(query).map((dept) => {
    const thisDept = getTeams({ _id: dept._id }, 'department')[0]
    const teams = getTeams({ parentId: dept._id })
    const teamsOfThisDept = [thisDept].concat(teams)

    return {
      teamIds: teamsOfThisDept.map(team => team._id),
      teamsNumber: teams.length,
      teams: teamsOfThisDept,
      volunteerNumber: teamsOfThisDept.reduce((sum, team) => sum + team.volunteerNumber, 0),
      shiftRate: sumSignupRates(teamsOfThisDept.map((team) => team.shiftRate)),
      metaleadRate: thisDept.leadRate,
      leadRate: sumSignupRates(teams.map((team) => team.leadRate)),
      ...dept,
    }
  })

  // All pending requests for tasks, shifts and leads
  // isLead = false isn't used, so may not make much sense, it at least doesn't
  // leak any sensitive info
  service.getTeamStats = (teamId, isLead) => ({
    pendingRequests: getSignupCount({ parentId: teamId, status: 'pending' }),
    team: isLead && getTeams({ _id: teamId })[0],
    volunteerNumber: getVolunteerCount({ parentId: teamId, status: 'confirmed' }),
  })

  service.getDeptStats = (deptId, isLead) => {
    if (!isLead) {
      throw new Meteor.Error(403, 'Only able to get dept signup stats as a lead')
    }
    const dept = getDepts({ _id: deptId })[0]
    const signupQuery = {
      parentId: { $in: [deptId, ...(dept?.teamIds ?? [])] },
      status: 'pending',
    }
    const pendingRequests = collections.signups.find(signupQuery).fetch()
    return {
      dept,
      pendingRequests,
      pendingLeadRequests: pendingRequests.filter(({ type }) => type === 'lead'),
    }
  }

  return service
}
