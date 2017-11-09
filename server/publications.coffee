share.initPulications = (eventName) ->
  # console.log "publish #{eventName}"
  Meteor.publish "#{eventName}.Volunteers.team", (sel={}) ->
    # XXX managers / leads, etc can access private teams, all others are public
    if this.userId
      share.Team.find(sel)

  Meteor.publish "#{eventName}.Volunteers.division", () ->
    if this.userId
      share.Division.find()

  Meteor.publish "#{eventName}.Volunteers.department", () ->
    if this.userId
      share.Department.find()

  Meteor.publish "#{eventName}.Volunteers.teamShifts", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$in: ["public","requireApproval"]}
      share.TeamShifts.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.teamTasks", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$in: ["public","requireApproval"]}
      share.TeamTasks.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.lead", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$in: ["public","requireApproval"]}
      share.Lead.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.allDuties", (sel={},limit=1) ->
    # XXX sel can contain only a number of filters. I should checked
    # what we pass this this funtion
    if this.userId
      sel.policy = {$in: ["requireApproval","public"]}
      if Roles.userIsInRole(this.userId, [ 'manager' ]) then delete sel.policy
      s = share.TeamShifts.find(sel,{limit: limit / 3})
      t = share.TeamTasks.find(sel,{limit: limit / 3})
      l = share.Lead.find(sel,{limit: limit / 3})
      tt = share.Team.find(sel)
      d = share.Department.find()
      dd = share.Division.find()
      [s,t,l,tt,d,dd]

  Meteor.publish "#{eventName}.Volunteers.allDuties.byTeam", (teamId) ->
    if this.userId
      sel = {parentId: teamId}
      # XXX: I'm tired. refactor here !
      sel.policy = {$in: ["requireApproval","public"]}
      selt = {parentId: teamId, status: {$in: ["pending"]}}
      selt.policy = {$in: ["requireApproval","public"]}
      if Roles.userIsInRole(this.userId, [ 'manager' ])
        delete sel.policy
        delete selt.policy
        delete selt.status
      tasks = share.TaskSignups.find({teamId: teamId})
      shifts = share.ShiftSignups.find({teamId: teamId})
      s = share.TeamShifts.find(sel)
      t = share.TeamTasks.find(selt)
      l = share.Lead.find({parentId: teamId})
      tt = share.Team.find({_id: teamId})
      # XXX: restrict to dept and div related to this team ...
      d = share.Department.find()
      dd = share.Division.find()
      [tasks,shifts,s,t,l,tt,d,dd]

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
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.TeamShifts.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.teamTasks.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.TeamTasks.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.lead.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.Lead.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.department.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.Department.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.team.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.Team.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.taskSignups", () ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.TaskSignups.find()
      else
        share.TaskSignups.find({usersId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.shiftSignups", () ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.ShiftSignups.find()
      else
        share.ShiftSignups.find({usersId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.taskSignups.byShift", (shiftId) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.TaskSignups.find({shiftId: shiftId})
      else
        share.TaskSignups.find({usersId: this.userId, shiftId: shiftId})

  Meteor.publish "#{eventName}.Volunteers.shiftSignups.byShift", (shiftId) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.ShiftSignups.find({shiftId: shiftId})
      else
        share.ShiftSignups.find({usersId: this.userId, shiftId: shiftId})

  Meteor.publish "#{eventName}.Volunteers.teamShiftsUser", () ->
    if this.userId
      l = share.ShiftSignups.find({usersId: this.usersId}).map((e) -> e._id)
      share.TeamShifts.find({_id: {$in: l}})

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", () ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        share.VolunteerForm.find()
      else
        share.VolunteerForm.find({userId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.users", () ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager" ])
        Meteor.users.find()
