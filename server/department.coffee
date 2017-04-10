import SimpleSchema from 'simpl-schema'

Meteor.methods 'Volunteers.department.remove': (Id) ->
  console.log ["Volunteers.department.remove", Id]
  check(Id,String)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Department.remove(Id)

Meteor.methods 'Volunteers.department.insert': (doc) ->
  console.log ["Volunteers.department.insert",doc]
  SimpleSchema.validate(doc, share.Schemas.Department)
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Department.insert(doc)

Meteor.methods 'Volunteers.department.update': (doc) ->
  console.log ["Volunteers.department.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.Department,{modifier:true})
  if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
    share.Department.update(doc._id,doc.modifier)
