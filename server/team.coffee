import SimpleSchema from 'simpl-schema'

Meteor.methods 'Volunteers.team.remove': (teamId) ->
  console.log ["Volunteers.team.remove", teamId]
  check(teamId,String)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    console.log "Remove all shifts related to this team"
    share.Team.remove(teamId)

Meteor.methods 'Volunteers.team.insert': (doc) ->
  console.log ["Volunteers.team.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.Team)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Team.insert(doc)

Meteor.methods 'Volunteers.team.update': (doc) ->
  console.log ["Volunteers.team.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.Team,{ modifier: true })
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Team.update(doc._id,doc.modifier)
# ------------------
Meteor.methods 'Volunteers.lead.insert': (doc) ->
  console.log ["Volunteers.lead.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.Lead)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Lead.insert(doc)

Meteor.methods 'Volunteers.lead.update': (doc) ->
  console.log ["Volunteers.lead.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.Lead,{modifier:true})
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Lead.update(doc._id,doc.modifier)

Meteor.methods 'Volunteers.lead.remove': (id) ->
  console.log ["Volunteers.lead.remove",id]
  check(id,String)
  uid = Meteor.userId()
  if (id == uid) || (Roles.userIsInRole(uid, [ 'manager' ]))
    share.Lead.remove(id)
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

Meteor.methods 'Volunteers.teamShifts.remove': (Id) ->
  console.log ["Volunteers.teamShifts.remove",Id]
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

Meteor.methods 'Volunteers.teamTasks.remove': (Id) ->
  console.log ["Volunteers.teamTasks.remove",Id]
  check(Id,String)
  uid = Meteor.userId()
  if (userId == uid) || (Roles.userIsInRole(uid, [ 'manager' ]))
    share.TeamTasks.remove(Id)
