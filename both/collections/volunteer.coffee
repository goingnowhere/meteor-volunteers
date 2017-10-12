import SimpleSchema from 'simpl-schema'

share.VolunteerForm = new Mongo.Collection 'Volunteers.volunteerForm'

share.Schemas.VolunteerForm = new SimpleSchema(
  userId:
    type: String
    optional: true
    autoValue: () -> this.userId
    autoform:
      omit: true
  createdAt:
    type: Date
    optional: true
    autoValue: () ->
      if this.isInsert then return new Date
      else this.unset()
    autoform:
      omit: true
  # notes:
  #   type: String
  #   label: () -> TAPi18n.__("notes")
  #   optional: true
  #   max: 1000
  #   autoform:
  #     rows:4
  # private_notes:
  #   type: String
  #   label: () -> TAPi18n.__("private_notes")
  #   optional: true
  #   max: 1000
  #   autoform:
  #     rows:2
)

share.VolunteerForm.attachSchema(share.Schemas.VolunteerForm)

share.form = new ReactiveVar(share.VolunteerForm)

commonSignups = new SimpleSchema(
  teamId: String
  shiftId: String
  userId: String
  status:
    type: String
    allowedValues: ["confirmed", "pending", "refused", "bailed"]
    autoform:
      omit: true
      defaultValue: "pending"
)
share.ShiftSignups = new Mongo.Collection 'Volunteers.shiftSignups'
share.Schemas.ShiftSignups = commonSignups
share.ShiftSignups.attachSchema(share.Schemas.ShiftSignups)
share.TaskSignups = new Mongo.Collection 'Volunteers.taskSignups'
share.Schemas.TaskSignups = commonSignups
share.TaskSignups.attachSchema(share.Schemas.TaskSignups)

# share.Tasks = new Mongo.Collection 'Volunteers.tasks'
# share.Schemas.Tasks = new SimpleSchema(
#   teamId: String
#   taskId: String
#   userId: [String]
# )
# share.Tasks.attachSchema(share.Schemas.Tasks)

share.extendVolunteerForm = (data) ->
  console.log ["VolunteerForm extend", data.form]
  schema = share.Schemas.VolunteerForm
  ss = FormBuilder.toSimpleSchema(data)
  schema.extend(ss)
  share.VolunteerForm.attachSchema(schema)
  share.form.set(share.VolunteerForm)

# rerun both on client and server thanks to peerlibrary:server-autorun
# if Meteor.isServer
# Tracker.autorun () ->
# console.log ["VolunteerForm extend autorun"]
# Update the VolunteersForm schema each time the Form is updated. This should
# both on client and server side.
FormBuilder.Collections.DynamicForms.find({name: "VolunteerForm"}).observe(
  added: (doc) -> share.extendVolunteerForm(doc)
  changed: (doc) -> share.extendVolunteerForm(doc)
  removed: (doc) -> share.extendVolunteerForm(doc)
)
