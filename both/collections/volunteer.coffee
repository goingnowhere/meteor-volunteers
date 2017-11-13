import SimpleSchema from 'simpl-schema'

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

share.form = new ReactiveVar(share.VolunteerForm)

commonSignups = new SimpleSchema(
  teamId: String
  shiftId: String
  userId: String
  createdAt:
    type: Date
    optional: true
    autoValue: () ->
      if this.isInsert then return new Date
      else this.unset()
    autoform:
      omit: true
  status:
    type: String
    allowedValues: ["confirmed", "pending", "refused", "bailed"]
    autoform:
      omit: true
      defaultValue: "pending"
)
share.Schemas.ShiftSignups = commonSignups
share.Schemas.TaskSignups = commonSignups

# share.Tasks = new Mongo.Collection 'Volunteers.tasks'
# share.Schemas.Tasks = new SimpleSchema(
#   teamId: String
#   taskId: String
#   userId: [String]
# )
# share.Tasks.attachSchema(share.Schemas.Tasks)

share.extendVolunteerForm = (data) ->
  # console.log ["VolunteerForm extend", data.form]
  schema = share.Schemas.VolunteerForm
  ss = FormBuilder.toSimpleSchema(data)
  schema.extend(ss)
  share.VolunteerForm.attachSchema(schema)
  share.form.set(share.VolunteerForm)

# Update the VolunteersForm schema each time the Form is updated. This should
# both on client and server side.
FormBuilder.Collections.DynamicForms.find({name: "VolunteerForm"}).observe(
  added: (doc) -> share.extendVolunteerForm(doc)
  changed: (doc) -> share.extendVolunteerForm(doc)
  removed: (doc) -> share.extendVolunteerForm(doc)
)
