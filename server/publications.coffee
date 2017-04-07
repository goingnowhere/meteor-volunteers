
Meteor.publish 'Volunteers.teams', () ->
  sel = {visibility: "public"}
  share.Teams.find(sel)

Meteor.publish 'Volunteers.teamShiftsUser', () ->
  l = share.Shifts.find({usersId: this.usersId}).map((e) -> e._id)
  share.TeamShifts.find({_id: {$in: l}})

Meteor.publish 'Volunteers.teamTasksUser', () ->
  l = share.Tasks.find({usersId: this.usersId}).map((e) -> e._id)
  share.TeamTasks.find({_id: {$in: l}})

Meteor.publish 'Volunteers.teamShifts', (sel={},limit=1) ->
  if sel then sel.visibility = "public"
  console.log "filter",sel
  console.log 'limit',limit
  share.TeamShifts.find(sel,{limit: limit})

Meteor.publish 'Volunteers.teamShifts.backend', (teamId) ->
  if Roles.userIsInRole(this.userId, [ 'manager' ])
    share.TeamShifts.find({teamId: teamId})

Meteor.publish 'Volunteers.teamTasks.backend', (teamId) ->
  if Roles.userIsInRole(this.userId, [ 'manager' ])
    share.TeamTasks.find({teamId: teamId})

Meteor.publish 'Volunteers.teamTasks', (sel={}) ->
  if sel then sel.visibility = "public"
  share.TeamTasks.find(sel)

Meteor.publish 'Volunteers.shifts', () ->
  if Roles.userIsInRole(this.userId, [ 'manager' ])
    share.Shifts.find()
  else
    # I could limit the visibility to the _id so not to
    # leak who else choose this shift ...
    share.Shifts.find({usersId: this.userId})

Meteor.publish 'Volunteers.tasks', () ->
  if Roles.userIsInRole(this.userId, [ 'manager' ])
    share.Tasks.find()
  else
    Tasks.find({usersId: this.userId})

Meteor.publish 'Volunteers.volunteerForm', () ->
  if Roles.userIsInRole(this.userId, [ 'manager' ])
    share.VolunteerForm.find()
  else
    share.VolunteerForm.find({userId: this.userId})

Meteor.publish "Volunteers.users", () ->
  if Roles.userIsInRole(this.userId, [ 'manager' ])
    Meteor.users.find()
