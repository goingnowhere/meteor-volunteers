
Meteor.publish 'Volunteers.team', () ->
  if this.userId
    sel = {visibility: "public"}
    share.Team.find(sel)

Meteor.publish 'Volunteers.division', () ->
  if this.userId
    sel = {visibility: "public"}
    share.Division.find(sel)

Meteor.publish 'Volunteers.department', () ->
  if this.userId
    sel = {visibility: "public"}
    share.Department.find(sel)

Meteor.publish 'Volunteers.teamShifts', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    share.TeamShifts.find(sel,{limit: limit})

Meteor.publish 'Volunteers.teamTasks', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    share.TeamTasks.find(sel,{limit: limit})

Meteor.publish 'Volunteers.lead', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    share.Lead.find(sel,{limit: limit})

Meteor.publish 'Volunteers.allDuties', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    s = share.TeamShifts.find(sel,{limit: limit / 3})
    t = share.TeamTasks.find(sel,{limit: limit / 3})
    l = share.Lead.find(sel,{limit: limit / 3})
    tt = share.Team.find(sel)
    [s,t,l,tt]

Meteor.publish 'Volunteers.teamShifts.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamShifts.find({teamId: id})

Meteor.publish 'Volunteers.teamTasks.backend', (id) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamTasks.find({teamId: id})

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

Meteor.publish 'Volunteers.shifts', () ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.Shifts.find()
    else
      # I could limit the visibility to the _id so not to
      # leak who else choose this shift ...
      share.Shifts.find({usersId: this.userId})

Meteor.publish 'Volunteers.teamShiftsUser', () ->
  if this.userId
    l = share.Shifts.find({usersId: this.usersId}).map((e) -> e._id)
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
