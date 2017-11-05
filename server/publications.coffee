share.initPulications = (eventName) ->
  # console.log "publish #{eventName}"
  Meteor.publish "#{eventName}.Volunteers.team", () ->
    if this.userId
      share.Team.find()

  Meteor.publish "#{eventName}.Volunteers.division", () ->
    if this.userId
      share.Division.find()

  Meteor.publish "#{eventName}.Volunteers.department", () ->
    if this.userId
      share.Department.find()

  Meteor.publish "#{eventName}.Volunteers.teamShifts", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$or: ["public","requireApproval"]}
      share.TeamShifts.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.teamTasks", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$or: ["public","requireApproval"]}
      share.TeamTasks.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.lead", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$or: ["public","requireApproval"]}
      share.Lead.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.allDuties", (sel={},limit=1) ->
    if this.userId
      sel.policy = {$in: ["requireApproval","public"]}
      s = share.TeamShifts.find(sel,{limit: limit / 3})
      t = share.TeamTasks.find(sel,{limit: limit / 3})
      l = share.Lead.find(sel,{limit: limit / 3})
      tt = share.Team.find(sel)
      [s,t,l,tt]

  Meteor.publish "#{eventName}.Volunteers.allDuties.byUser", () ->
    if this.userId
      tasks = share.TaskSignups.find({userId: this.userId})
      shifts = share.ShiftSignups.find({userId: this.userId})
      # leads = share.LeadSignups.find({usersId: this.userId})
      s = share.TeamShifts.find({_id: {$in: shifts.map((e) -> e.shiftId)}})
      t = share.TeamTasks.find({_id: {$in: tasks.map((e) -> e.shiftId)}})
      l = share.Lead.find()#{_id: {$in: leads.map((e) -> e.shiftId)}})
      tt = share.Team.find()
      [s,t,l,tt]

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
