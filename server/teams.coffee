import SimpleSchema from 'simpl-schema'

Meteor.methods 'Volunteers.teams.remove': (teamId) ->
  console.log ["Volunteers.teams.remove", teamId]
  check(teamId,String)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    console.log "Remove all shifts related to this team"
    share.Teams.remove(teamId)

Meteor.methods 'Volunteers.teams.insert': (doc) ->
  console.log ["Volunteers.teams.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.Teams)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Teams.insert(doc)

Meteor.methods 'Volunteers.teams.update': (doc) ->
  console.log ["Volunteers.teams.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.Teams,{ modifier: true })
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Teams.update(doc._id,doc.modifier)
# ------------------
Meteor.methods 'Volunteers.teamLeads.insert': (doc) ->
  console.log ["Volunteers.teamLeads.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.TeamLeads)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.TeamLeads.insert(doc)

Meteor.methods 'Volunteers.teamLeads.update': (doc) ->
  console.log ["Volunteers.teamLeads.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.TeamLeads,{modifier:true})
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.TeamLeads.update(doc._id,doc.modifier)

Meteor.methods 'Volunteers.teamsLeads.remove': (Id) ->
  console.log ["Volunteers.teamsLeads.remove",Id]
  check(Id,String)
  uid = Meteor.userId()
  if (userId == uid) || (Roles.userIsInRole(uid, [ 'manager' ]))
    share.TeamLeads.remove(Id)
# ------------------
Meteor.methods 'Volunteers.teamShifts.insert': (doc) ->
  console.log ["Volunteers.teamShifts.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.TeamShifts)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.TeamShifts.insert(doc)

Meteor.methods 'Volunteers.teamShifts.update': (doc) ->
  console.log ["Volunteers.teamShifts.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.TeamShifts,{modifier:true})
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.TeamShifts.update(doc._id,doc.modifier)

Meteor.methods 'Volunteers.teamsShifts.remove': (Id) ->
  console.log ["Volunteers.teamsShifts.remove",Id]
  check(Id,String)
  uid = Meteor.userId()
  if (userId == uid) || (Roles.userIsInRole(uid, [ 'manager' ]))
    share.TeamShifts.remove(Id)
# ------------------
Meteor.methods 'Volunteers.teamTasks.insert': (doc) ->
  console.log ["Volunteers.teamTasks.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.TeamTasks)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.TeamTasks.insert(doc)

Meteor.methods 'Volunteers.teamTasks.update': (doc) ->
  console.log ["Volunteers.teamTasks.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.TeamTasks,{modifier:true})
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.TeamTasks.update(doc._id,doc.modifier)

Meteor.methods 'Volunteers.teamsTasks.remove': (Id) ->
  console.log ["Volunteers.teamsTasks.remove",Id]
  check(Id,String)
  uid = Meteor.userId()
  if (userId == uid) || (Roles.userIsInRole(uid, [ 'manager' ]))
    share.TeamTasks.remove(Id)
