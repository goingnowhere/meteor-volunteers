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

Meteor.methods 'Volunteers.shifts.remove': (shiftId) ->
  console.log ["Volunteers.shifts.remove",shiftId]
  check(shiftId,String)
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.Shifts.remove(shiftId)

Meteor.methods 'Volunteers.shifts.update': (doc) ->
  console.log ["Volunteers.shifts.update",doc]
  SimpleSchema.validate(doc.modifier,share.Schemas.Shifts,{ modifier: true })
  userId = Meteor.userId()
  if Roles.userIsInRole(userId, [ 'manager' ])
    share.Shifts.update(doc._id, doc.modifier)

Meteor.methods 'Volunteers.shifts.insert': (doc) ->
  console.log ["Volunteers.shifts.insert",doc]
  SimpleSchema.validate(doc,share.Schemas.Shifts.omit('status'))
  userId = Meteor.userId()
  if (doc.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
    t = (
      if doc.type == "shift"
        share.TeamShifts.findOne(doc.shiftId)
      else
        share.TeamTasks.findOne(doc.shiftId))
    console.log "aa",t
    status = (
      if t.policy == "public" then "confirmed"
      else if t.policy == "requireApproval" then "pending")
    console.log "aa",status
    if status
      doc.status = status
      console.log t,doc
      share.Shifts.insert(doc)

Meteor.methods 'Volunteers.shifts.bail': (sel) ->
  console.log ["Volunteers.shifts.bail",sel]
  SimpleSchema.validate(sel,share.Schemas.Shifts.omit('status'))
  userId = Meteor.userId()
  if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
    console.log "AAAA"
    share.Shifts.update(sel,{$set: {status: "bailed"}})

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
