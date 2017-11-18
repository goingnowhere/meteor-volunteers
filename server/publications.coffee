share.initPulications = (eventName) ->

  filterForPublic = (userId, sel) =>
    if !Roles.userIsInRole(userId, 'manager', eventName)
      # getRolesForUser includes all roles, e.g. if user is lead of a department,
      # returns the department and all teams within it
      allOrgUnitIds = Roles.getRolesForUser(Meteor.userId(), eventName)
      sel.policy = { $in: ["public", "requireApproval"] }
      if allOrgUnitIds.length > 0
        if sel.parentId?
          delete sel.policy if sel.parentId in allOrgUnitIds
        else
          sel =
            $or: [
              parentId: { $in: allOrgUnitIds },
              sel
            ]
    sel

  # console.log "publish #{eventName}"
  Meteor.publish "#{eventName}.Volunteers.team", (sel={}) ->
    # XXX managers / leads, etc can access private teams, all others are public
    if this.userId # FIXME
      share.Team.find(sel)

  Meteor.publish "#{eventName}.Volunteers.division", () ->
    if this.userId # FIXME
      share.Division.find()

  Meteor.publish "#{eventName}.Volunteers.department", () ->
    if this.userId # FIXME
      share.Department.find()

  Meteor.publish "#{eventName}.Volunteers.teamShifts", (sel={},limit=1) ->
    if this.userId
      sel = filterForPublic(this.userId, sel)
      share.TeamShifts.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.teamTasks", (sel={},limit=1) ->
    if this.userId
      sel = filterForPublic(this.userId, sel)
      share.TeamTasks.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.lead", (sel={},limit=1) ->
    if this.userId
      sel = filterForPublic(this.userId, sel)
      share.Lead.find(sel)

  Meteor.publish "#{eventName}.Volunteers.allDuties", (sel={},limit=1) ->
    # XXX sel can contain only a number of filters. I should checked
    # what we pass this this funtion
    if this.userId
      # sel.policy = {$in: ["requireApproval","public"]}
      # if Roles.userIsInRole(this.userId, [ 'manager' ]) then delete sel.policy
      sel = filterForPublic(this.userId, sel)
      s = share.TeamShifts.find(sel,{limit: limit / 3})
      t = share.TeamTasks.find(sel,{limit: limit / 3})
      l = share.Lead.find(sel,{limit: limit / 3})
      tt = share.Team.find(sel) # FIXME
      d = share.Department.find()
      dd = share.Division.find()
      [s,t,l,tt,d,dd]

  Meteor.publish "#{eventName}.Volunteers.allDuties.byTeam", (teamId) ->
    if this.userId
      selShifts = {parentId: teamId}
      # XXX: I'm tired. refactor here !
      selShifts.policy = {$in: ["requireApproval","public"]}
      selTasks = {parentId: teamId, status: {$in: ["pending"]}}
      selTasks.policy = {$in: ["requireApproval","public"]}
      if Roles.userIsInRole(this.userId, [ 'manager', teamId ], eventName)
        delete selShifts.policy
        delete selTasks.policy
        delete selTasks.status
      taskSignups = share.TaskSignups.find({teamId: teamId})
      shiftSignups = share.ShiftSignups.find({teamId: teamId})
      shifts = share.TeamShifts.find(selShifts)
      tasks = share.TeamTasks.find(selTasks)
      leads = share.Lead.find({parentId: teamId})
      team = share.Team.find({_id: teamId})
      # XXX: restrict to dept and div related to this team ...
      d = share.Department.find()
      dd = share.Division.find()
      [taskSignups,shiftSignups,shifts,tasks,leads,team,d,dd]

  Meteor.publish "#{eventName}.Volunteers.allDuties.byUser", () ->
    if this.userId
      # sel.policy = {$in: ["requireApproval","public"]}
      # if Roles.userIsInRole(this.userId, [ 'manager' ]) then delete sel.policy
      tasks = share.TaskSignups.find({userId: this.userId, status: {$in: ["confirmed", "pending","refused"]}})
      shifts = share.ShiftSignups.find({userId: this.userId, status: {$in: ["confirmed", "pending","refused"]}})
      shiftIds = shifts.map((e) -> e.shiftId).concat(tasks.map((e) -> e.shiftId))
      teamIds = shifts.map((e) -> e.teamId).concat(tasks.map((e) -> e.teamId))
      s = share.TeamShifts.find({_id: {$in: shiftIds}})
      t = share.TeamTasks.find({_id: {$in: shiftIds}})
      l = share.Lead.find({parentId: {$in: teamIds}})
      tt = share.Team.find({_id: {$in: teamIds}})
      d = share.Department.find()
      dd = share.Division.find()
      [tasks,shifts,s,t,l,tt,d,dd]

  Meteor.publish "#{eventName}.Volunteers.teamShifts.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.TeamShifts.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.teamTasks.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.TeamTasks.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.lead.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.Lead.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.department.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.Department.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.team.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.Team.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.taskSignups", () ->
    if this.userId
      # if Roles.userIsInRole(this.userId, [ "manager" ])# FIXME
        share.TaskSignups.find()
      # else
      #   share.TaskSignups.find({userId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.shiftSignups", () ->
    if this.userId
      # if Roles.userIsInRole(this.userId, [ "manager" ])# FIXME
        share.ShiftSignups.find()
      # else
      #   share.ShiftSignups.find({userId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.taskSignups.byShift", (shiftId) ->
    if this.userId
      teamId = share.TeamTasks.findOne({ _id: shiftId })?.parentId
      if Roles.userIsInRole(this.userId, [ "manager", teamId ], eventName)
        share.TaskSignups.find({shiftId: shiftId})
      else
        share.TaskSignups.find({userId: this.userId, shiftId: shiftId})

  Meteor.publish "#{eventName}.Volunteers.shiftSignups.byShift", (shiftId) ->
    if this.userId
      teamId = share.TeamTasks.findOne({ _id: shiftId })?.parentId
      if Roles.userIsInRole(this.userId, [ "manager", teamId ], eventName)
        share.ShiftSignups.find({shiftId: shiftId})
      else
        share.ShiftSignups.find({userId: this.userId, shiftId: shiftId})

  Meteor.publish "#{eventName}.Volunteers.teamShiftsUser", () ->
    if this.userId
      l = share.ShiftSignups.find({userId: this.userId}).map((e) -> e._id)
      share.TeamShifts.find({_id: {$in: l}})

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", () ->
    if this.userId
      # if Roles.userIsInRole(this.userId, [ "manager" ])# FIXME
        share.VolunteerForm.find()
      # else
      #   share.VolunteerForm.find({userId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.users", () ->
    if this.userId
      # if Roles.userIsInRole(this.userId, [ "manager" ])# FIXME
        Meteor.users.find({}, { fields: { emails: 1, profile: 1, roles: 1 } })
