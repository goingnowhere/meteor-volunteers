getDuty = (sel, type, duty, signup) ->
  sort = {sort: {start: 1, priority: 1}}
  duty.find(sel).map((v) ->
    confirmed = signup.find({status: "confirmed", shiftId: v._id},sort).count()
    _.extend(v,
      type: type
      duration: moment.duration(v.end - v.start).humanize()
      confirmed: confirmed
      needed: v.min - confirmed)
    return v
  )

# return a shift/task/lead document together with updated signups information
share.getShifts = (sel) -> getDuty(sel,"shift",share.TeamShifts,share.ShiftSignups)
share.getProjects = (sel) -> getDuty(sel,"project",share.Projects,share.ProjectSignups)
share.getTasks = (sel) -> getDuty(sel,"task",share.TeamTasks,share.TaskSignups)
share.getLeads = (sel) -> getDuty(sel,"lead",share.Lead,share.LeadSignups)

rate = (l) ->
  _.reduce(l,(
    (acc,shift) -> {
      needed: acc.needed + shift.min,
      confirmed: acc.confirmed + shift.confirmed
    }
  ),{needed: 0, confirmed: 0})

getUnit = (sel,unit,type) ->
  unit.find(sel).map((u) ->
    u.leads = share.LeadSignups.find(
      {status: "confirmed", parentId: u._id}
      ).map((s) -> return s.userId)
    if type = "team"
      console.log u
      console.log share.getShifts({parentId: u._id})
      u.shiftRate = rate(share.getShifts({parentId: u._id}))
    return u
    )

class TeamStatsClass
  constructor: (@teamId) ->
  # all shifts that are not yet completely covered
  # can be ordered by priority to get all the important shifts that are
  # not covered
  shiftsLow: () ->
    _.filter(share.getShifts({parentId: @teamId}),((shift) -> shift.min < shift.signups))
  # all tasks that are not yet completely covered
  tasksLow: () ->
    _.filter(share.getTasks({parentId: @teamId}),((shift) -> shift.min < shift.signups))
  # All pending requests for tasks, shifts and leads
  pendingRequests: () -> []
  # total number of shifts vs total number of signups
  shiftRate: () -> rate(share.getShifts({parentId: @teamId}))
  # total number of tasks vs total number of signups
  taskRate: () -> rate(share.getTasks({parentId: @teamId}))
  # total number of volunteers only considering shifts
  volunteerNumber: () ->
    _.uniq(share.ShiftSignups.find(
      {parentId: @teamId},
      {sort: {userId: 1}, fields: {userId: true}}
      ).map((s) -> s.userId),true).length

class DepartmentStatsClass
  constructor: (@departmentId) ->
  # the list of teams of this Department with associated leads
  # can get the number by counting and order by teams without lead
  # or by the shiftRate or pendingRequests
  teams: () -> getUnit({parentId: @departmentId},share.Team,"team")
  leadsActivity: () -> []
  pendingRequests: () -> []
  # total number of volunteers involved with this Department
  volunteerRate: () ->
    _.reduce(getUnit({parentId: @departmentId},share.Team,"team"),
      (acc,t) -> {
        needed: acc.needed + t.shiftRate.needed,
        confirmed: acc.confirmed + t.shiftRate.confirmed
      }
    )
  #signups over time

# TODO
class DivisionStatsClass
  constructor: (@divisionId) ->
  teamsNumber: () -> 0
  teamsWithLead: () -> []
  teamsLowRate: () -> []
  teamsPending: () -> []
  leadsActivity: () -> []
  volunteerNumber: () -> 0
  #signups over time
  overallRate: () -> 0

share.TeamStats = (id) -> new TeamStatsClass(id)
share.DepartmentStats = (id) -> new DepartmentStatsClass(id)
