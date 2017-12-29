getDuty = (sel, duty, signup) ->
  duty.find(sel).map((d) ->
    d.signups = signup.find({status: "confirmed", shiftId: d._id}).count()
    return d
    )

getShifts = (sel) -> getDuty(sel,share.TeamShifts,share.ShiftSignups)
getTasks = (sel) -> getDuty(sel,share.TeamTasks,share.TaskSignups)
getLeads = (sel) -> getDuty(sel,share.Lead,share.LeadSignups)

rate = (l) ->
  _.reduce(l,(
    (acc,shift) -> {
      needed: acc.needed + shift.min,
      signups: acc.signups + shift.signups
    }
  ),{needed: 0, signups: 0})

getUnit = (sel,unit,type) ->
  unit.find(sel).map((u) ->
    u.leads = share.LeadSignups.find(
      {status: "confirmed", parentId: u._id}
      ).map((s) -> return s.userId)
    if type = "team"
      u.shiftRate = rate(getShifts({parentId: u._id}))
    return u
    )

class TeamStatsClass
  constructor: (@teamId) ->
  # all shifts that are not yet completely covered
  # can be ordered by priority to get all the important shifts that are
  # not covered
  shiftsLow: () ->
    _.filter(getShifts({parentId: @teamId}),((shift) -> shift.min < shift.signups))
  # all tasks that are not yet completely covered
  tasksLow: () ->
    _.filter(getTasks({parentId: @teamId}),((shift) -> shift.min < shift.signups))
  # All pending requests for tasks, shifts and leads
  pendingRequests: () -> []
  # total number of shifts vs total number of signups
  shiftRate: () -> rate(getShifts({parentId: @teamId}))
  # total number of tasks vs total number of signups
  taskRate: () -> rate(getTasks({parentId: @teamId}))
  # total number of volunteers only considering shifts
  volunteerNumber: () ->
    share.ShiftSignups.find({parentId: @teamId}).count()
  #signups over time

class DepartmentStatsClass
  constructor: (@departmentId) ->
  # the list of teams of this Department with associated leads
  # can get the number by counting and order by teams without lead
  # or by the shiftRate or pendingRequests
  teams: () -> getUnit({parentId: @departmentId},share.Team)
  leadsActivity: () -> []
  # total number of volunteers involved with this Department
  volunteerRate: () ->
    _.reduce(getUnit({parentId: @departmentId},share.Team),
      (acc,t) -> {
        needed: acc.needed + t.shiftRate.needed,
        signups: acc.signups + t.shiftRate.signups
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

share.TeamStats = (teamId) -> new TeamStatsClass(teamId)
