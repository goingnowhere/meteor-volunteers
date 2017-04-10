import SimpleSchema from 'simpl-schema'

Meteor.methods 'Volunteers.division.remove': (Id) ->
  console.log ["Volunteers.division.remove", Id]
  check(Id,String)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Division.remove(Id)

Meteor.methods 'Volunteers.division.insert': (doc) ->
  console.log ["Volunteers.division.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.Division)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Division.insert(doc)

Meteor.methods 'Volunteers.division.update': (doc) ->
  console.log ["Volunteers.division.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.Division,{ modifier: true })
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Division.update(doc._id,doc.modifier)
