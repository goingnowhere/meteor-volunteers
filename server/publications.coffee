
Meteor.publish 'Volunteers.team', () ->
  if this.userId
    share.Team.find()

Meteor.publish 'Volunteers.division', () ->
  if this.userId
    share.Division.find()

Meteor.publish 'Volunteers.department', () ->
  if this.userId
    share.Department.find()

Meteor.publish 'Volunteers.teamShifts', (sel={},limit=1) ->
  if this.userId
    sel.policy = {$or: ["public","requireApproval"]}
    share.TeamShifts.find(sel,{limit: limit})

Meteor.publish 'Volunteers.teamTasks', (sel={},limit=1) ->
  if this.userId
    sel.policy = {$or: ["public","requireApproval"]}
    share.TeamTasks.find(sel,{limit: limit})

Meteor.publish 'Volunteers.lead', (sel={},limit=1) ->
  if this.userId
    sel.policy = {$or: ["public","requireApproval"]}
    share.Lead.find(sel,{limit: limit})

Meteor.publish 'Volunteers.allDuties', (sel={},limit=1) ->
  if this.userId
    sel.policy = {$in: ["requireApproval","public"]}
    s = share.TeamShifts.find(sel,{limit: limit / 3})
    t = share.TeamTasks.find(sel,{limit: limit / 3})
    l = share.Lead.find(sel,{limit: limit / 3})
    tt = share.Team.find(sel)
    [s,t,l,tt]

Meteor.publish 'Volunteers.teamShifts.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamShifts.find({parentId: id})

Meteor.publish 'Volunteers.teamTasks.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamTasks.find({parentId: id})

Meteor.publish 'Volunteers.lead.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.Lead.find({parentId: id})

Meteor.publish 'Volunteers.department.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.Department.find({parentId: id})

Meteor.publish 'Volunteers.team.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.Team.find({parentId: id})

Meteor.publish 'Volunteers.taskSignups', () ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TaskSignups.find()
    else
      share.TaskSignups.find({usersId: this.userId})

Meteor.publish 'Volunteers.shiftSignups', () ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.ShiftSignups.find()
    else
      share.ShiftSignups.find({usersId: this.userId})

Meteor.publish 'Volunteers.taskSignups.byShift', (shiftId) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TaskSignups.find({shiftId: shiftId})
    else
      share.TaskSignups.find({usersId: this.userId, shiftId: shiftId})

Meteor.publish 'Volunteers.shiftSignups.byShift', (shiftId) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.ShiftSignups.find({shiftId: shiftId})
    else
      share.ShiftSignups.find({usersId: this.userId, shiftId: shiftId})

Meteor.publish 'Volunteers.teamShiftsUser', () ->
  if this.userId
    l = share.ShiftSignups.find({usersId: this.usersId}).map((e) -> e._id)
    share.TeamShifts.find({_id: {$in: l}})

Meteor.publish 'Volunteers.volunteerForm', () ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.VolunteerForm.find()
    else
      share.VolunteerForm.find({userId: this.userId})

Meteor.publish "Volunteers.users", () ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      Meteor.users.find()
