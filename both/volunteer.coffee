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

share.extendVolunteerForm = () ->
  data = FormBuilder.Collections.DynamicForms.findOne({name: "VolunteerForm"})
  schema = share.Schemas.VolunteerForm
  ss = FormBuilder.toSimpleSchema(data)
  schema.extend(ss)
  share.VolunteerForm.attachSchema(schema)
  share.form.set(share.VolunteerForm)

# rerun both on client and server thanks to peerlibrary:server-autorun
if Meteor.isServer
  Tracker.autorun () ->
    console.log ["VolunteerForm extend autorun server"]
    share.extendVolunteerForm()
