import moment from 'moment-timezone'

moment.tz.setDefault(share.timezone.get())

# signups -> userId list
uniqueVolunteers = (allSignups) ->
  if allSignups
    _.chain(allSignups)
    .pluck('userId')
    .uniq()
    .value()
  else []

# (sel,type,duty,signup) -> {
#   type: string,
#   duration,
#   confirmed: int,
#   needed: int,
#   volunteers: userId list } list
# (sel,type,duty,signup) -> duty list
getDuties = (sel, type, duty, signup) ->
  sort = {sort: {start: 1, priority: 1}}
  duty.find(sel, sort).map((v) ->
    confirmedSignups = signup.find({status: "confirmed", shiftId: v._id},sort)
    signups = confirmedSignups.fetch()
    volunteers = uniqueVolunteers(signups)
    volunteerNumber = confirmedSignups.count()
    return _.extend(v,
      type: type
      duration: moment.duration(v.end - v.start).humanize()
      confirmed: volunteerNumber
      needed: Math.max(0,v.min - volunteerNumber)
      volunteers: volunteers
      signups: signups
    )
  )

# return a shift/task/lead document together with updated signups information
share.getShifts = (sel) -> getDuties(sel,"shift",share.TeamShifts,share.ShiftSignups)
share.getProjects = (sel) -> getDuties(sel,"project",share.Projects,share.ProjectSignups)
share.getTasks = (sel) -> getDuties(sel,"task",share.TeamTasks,share.TaskSignups)
share.getLeads = (sel) -> getDuties(sel,"lead",share.Lead,share.LeadSignups)

# sel -> signup list
getSignups = (sel) ->
  shifts = share.ShiftSignups.find(sel).fetch()
  projects = share.ProjectSignups.find(sel).fetch()
  leads = share.LeadSignups.find(sel).fetch()
  tasks = share.TaskSignups.find(sel).fetch()
  return shifts.concat(projects).concat(leads).concat(tasks)

# sel -> userId list
getVolunteers = (sel) ->
  allSignups = getSignups(sel)
  return uniqueVolunteers(allSignups)

# duties -> { needed: int , confirmed: int}
rate = (l) ->
  _.reduce(l,(
    (acc,shift) -> {
      needed: acc.needed + (if shift.min then shift.min else 0),
      confirmed: acc.confirmed + (if shift.confirmed then shift.confirmed else 0)
    }
  ),{needed: 0, confirmed: 0})

# sel * type -> {
#   volunteers: userId list,
#   shiftRate -> { needed: int , confirmed: int},
#   leadRate -> { needed: int , confirmed: int},
#   volunteerNumber: int,
#   teamsNumber: int,
#   leads : userId list
#}
# sel * type -> unit list
getUnits = (sel,type) ->
  unit = (
    if type == "team" then share.Team
    else if type == "department" then share.Department
  )
  unit.find(sel).map((u) ->
    if type == "team"
      shifts = share.getShifts({parentId: u._id})
      leads = share.getLeads({parentId: u._id})
      u.volunteers = getVolunteers({parentId: u._id, status: 'confirmed'})
      u.shiftRate = rate(shifts)
      u.leadRate = rate(leads)
      u.volunteerNumber = u.volunteers.length
      u.leads = uniqueVolunteers(share.LeadSignups.find(sel).fetch())
    if type == "department"
      teamsOfThisDept = getUnits({parentId: u._id},"team")
      u.teamIds = _.pluck(teamsOfThisDept,'_id')
      u.teamsNumber = teamsOfThisDept.length
      u.shiftRate = _.reduce(teamsOfThisDept,
          (acc,t) -> (
            {
              needed: acc.needed + t.shiftRate.needed,
              confirmed: acc.confirmed + t.shiftRate.confirmed
            }
          ),
          { needed: 0, confirmed: 0 }
        )
      u.leadRate = _.reduce(teamsOfThisDept,
        (acc,t) -> {
          needed: acc.needed + t.leadRate.needed,
          confirmed: acc.confirmed + t.leadRate.confirmed
        },
        { needed: 0, confirmed: 0 }
      )
      u.volunteerNumber = _.chain(teamsOfThisDept)
        .map((t) -> t.volunteerNumber)
        .reduce(((acc,t) -> acc+t), 0 )
        .value()
    return u
    )

share.TeamStats = (parentId) ->
  # All pending requests for tasks, shifts and leads
  stats = {
    pendingRequests: getSignups({parentId, status:'pending'})
    team: getUnits({_id: parentId},"team")[0]
    volunteerNumber: getVolunteers({parentId, status: 'confirmed'}).length
  }
  share.UnitAggregation.upsert(parentId,{ $set: stats })
  return stats

share.DepartmentStats = (parentId) ->
  sel = {$or: [{_id: parentId},{parentId}]}
  dept = getUnits({_id: parentId},"department")[0]
  signupSel = { parentId: {$in: dept.teamIds}, status: 'pending'}
  pendingLeadRequests = share.LeadSignups.find(signupSel).count()
  volunteerNumber = getVolunteers(sel).length
  stats =  { dept, volunteerNumber, pendingLeadRequests }
  share.UnitAggregation.upsert(parentId,{ $set: stats })
  return stats

share.DivisionStats = (id) ->
  teamsNumber: () -> 0
  teamsWithLead: () -> []
  teamsLowRate: () -> []
  teamsPending: () -> []
  leadsActivity: () -> []
  volunteerNumber: () -> 0
  #signups over time
  overallRate: () -> 0
