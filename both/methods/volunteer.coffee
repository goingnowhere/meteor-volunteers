import SimpleSchema from 'simpl-schema'

Meteor.methods 'Volunteers.volunteerForm.remove': (formId) ->
  console.log ["Volunteers.volunteerForm.remove",formId]
  check(formId,String)
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.VolunteerForm.remove(formId)

Meteor.methods 'Volunteers.volunteerForm.update': (doc) ->
  console.log ["Volunteers.volunteerForm.update",doc]
  schema = share.VolunteerForm.simpleSchema()
  SimpleSchema.validate(doc.modifier,schema,{ modifier: true })
  userId = Meteor.userId()
  if (userId == doc.userId) || Roles.userIsInRole(userId, [ 'manager' ])
    share.VolunteerForm.update(doc._id,doc.modifier)

Meteor.methods 'Volunteers.volunteerForm.insert': (doc) ->
  console.log ["Volunteers.volunteerForm.insert",doc]
  schema = share.form.get().simpleSchema()
  SimpleSchema.validate(doc,schema)
  if Meteor.userId()
    doc.userId = Meteor.userId()
    share.form.get().insert(doc)

Meteor.methods 'Volunteers.shiftSignups.remove': (shiftId) ->
  console.log ["Volunteers.shiftSignups.remove",shiftId]
  check(shiftId,String)
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.ShiftSignups.remove(shiftId)

Meteor.methods 'Volunteers.shiftSignups.update': (doc) ->
  console.log ["Volunteers.shiftSignups.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.ShiftSignups,{ modifier: true })
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.ShiftSignups.update(doc._id, doc.modifier)

Meteor.methods 'Volunteers.shiftSignups.insert': (doc) ->
  console.log ["Volunteers.shiftSignups.insert",doc]
  SimpleSchema.validate(doc,share.Schemas.ShiftSignups.omit('status'))
  userId = Meteor.userId()
  if (doc.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
    teamShift = share.TeamShifts.findOne(doc.shiftId)
    status = (
      if teamShift.policy == "public" then "confirmed"
      else if teamShift.policy == "requireApproval" then "pending")
    if status
      doc.status = status
      share.ShiftSignups.insert(doc)

Meteor.methods 'Volunteers.shiftSignups.bail': (sel) ->
  console.log ["Volunteers.shiftSignups.bail",sel]
  SimpleSchema.validate(sel,share.Schemas.ShiftSignups.omit('status'))
  userId = Meteor.userId()
  if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
    share.ShiftSignups.update(sel,{$set: {status: "bailed"}})

Meteor.methods 'Volunteers.taskSignups.remove': (shiftId) ->
  console.log ["Volunteers.taskSignups.remove",shiftId]
  check(shiftId,String)
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.TaskSignups.remove(shiftId)

Meteor.methods 'Volunteers.taskSignups.update': (doc) ->
  console.log ["Volunteers.taskSignups.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.TaskSignups,{ modifier: true })
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.TaskSignups.update(doc._id, doc.modifier)

Meteor.methods 'Volunteers.taskSignups.insert': (doc) ->
  console.log ["Volunteers.taskSignups.insert",doc]
  SimpleSchema.validate(doc,share.Schemas.TaskSignups.omit('status'))
  userId = Meteor.userId()
  if (doc.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
    teamTask = share.TeamTasks.findOne(doc.shiftId)
    status = (
      if teamTask.policy == "public" then "confirmed"
      else if teamTask.policy == "requireApproval" then "pending")
    if status
      doc.status = status
      share.TaskSignups.insert(doc)

Meteor.methods 'Volunteers.taskSignups.bail': (sel) ->
  console.log ["Volunteers.taskSignups.bail",sel]
  SimpleSchema.validate(sel,share.Schemas.TaskSignups.omit('status'))
  userId = Meteor.userId()
  if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
    share.TaskSignups.update(sel,{$set: {status: "bailed"}})

# Meteor.methods 'Volunteers.tasks.remove': (taskId) ->
#   console.log ["Volunteers.tasks.remove",taskId]
#   check(taskId,String)
#   userId = Meteor.userId()
#   if Roles.userIsInRole(userId, [ 'manager' ])
#     share.Tasks.remove(taskId)
#
# Meteor.methods 'Volunteers.tasks.update': (doc) ->
#   console.log ["Volunteers.tasks.update",doc]
#   SimpleSchema.validate(doc.modifier,share.Schemas.Tasks,{ modifier: true })
#   userId = Meteor.userId()
#   if Roles.userIsInRole(userId, [ 'manager' ])
#     share.Tasks.update(doc._id, doc.modifier)
#
# Meteor.methods 'Volunteers.tasks.insert': (doc) ->
#   console.log ["Volunteers.tasks.insert",doc]
#   SimpleSchema.validate(doc,share.Schemas.Tasks)
#   userId = Meteor.userId()
#   if Roles.userIsInRole(userId, [ 'manager' ])
#     share.Tasks.insert(doc)
