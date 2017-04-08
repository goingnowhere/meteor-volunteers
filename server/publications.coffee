
Meteor.publish 'Volunteers.teams', () ->
  if this.userId
    sel = {visibility: "public"}
    share.Teams.find(sel)

Meteor.publish 'Volunteers.teamShifts', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    share.TeamShifts.find(sel,{limit: limit})

Meteor.publish 'Volunteers.teamTasks', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    share.TeamTasks.find(sel,{limit: limit})

Meteor.publish 'Volunteers.teamLeads', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    share.TeamLeads.find(sel,{limit: limit})

Meteor.publish 'Volunteers.allDuties', (sel={},limit=1) ->
  if this.userId
    if sel then sel.visibility = "public"
    s = share.TeamShifts.find(sel,{limit: limit / 3})
    t = share.TeamTasks.find(sel,{limit: limit / 3})
    l = share.TeamLeads.find(sel,{limit: limit / 3})
    tt = share.Teams.find(sel)
    [s,t,l,tt]

Meteor.publish 'Volunteers.teamShifts.backend', (teamId) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamShifts.find({teamId: teamId})

Meteor.publish 'Volunteers.teamTasks.backend', (teamId) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamTasks.find({teamId: teamId})

Meteor.publish 'Volunteers.teamLeads.backend', (teamId) ->
  if this.userId
    if Roles.userIsInRole(this.userId, [ 'manager' ])
      share.TeamLeads.find({teamId: teamId})

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
