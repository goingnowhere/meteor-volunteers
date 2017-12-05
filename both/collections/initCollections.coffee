import SimpleSchema from 'simpl-schema'

toShare = {
  collections: {}
}

toShare.initCollections = (eventName) ->
  toShare.collections.eventName = eventName

  prefix = "#{eventName}."

  # duties

  toShare.collections.TeamTasks = new Mongo.Collection "#{prefix}Volunteers.teamTasks"
  toShare.collections.TeamTasks.attachSchema(share.Schemas.TeamTasks)

  toShare.collections.TeamShifts = new Mongo.Collection "#{prefix}Volunteers.teamShifts"
  toShare.collections.TeamShifts.attachSchema(share.Schemas.TeamShifts)

  toShare.collections.Lead = new Mongo.Collection "#{prefix}Volunteers.lead"
  toShare.collections.Lead.attachSchema(share.Schemas.Lead)

  # Orga

  toShare.collections.Team = new Mongo.Collection "#{prefix}Volunteers.team"
  toShare.collections.Team.attachSchema(share.Schemas.Team)

  toShare.collections.Department = new Mongo.Collection "#{prefix}Volunteers.department"
  toShare.collections.Department.attachSchema(share.Schemas.Department)

  toShare.collections.Division = new Mongo.Collection "#{prefix}Volunteers.division"
  toShare.collections.Division.attachSchema(share.Schemas.Division)

  # User Form

  toShare.collections.VolunteerForm = new Mongo.Collection "#{prefix}Volunteers.volunteerForm"
  toShare.collections.VolunteerForm.attachSchema(share.Schemas.VolunteerForm)
  toShare.collections.form = new ReactiveVar(toShare.collections.VolunteerForm)

  toShare.collections.extendVolunteerForm = (data) ->
    form = toShare.collections.form.get()
    schema = new SimpleSchema(share.Schemas.VolunteerForm)
    newschema = schema.extend(FormBuilder.toSimpleSchema(data))
    form.attachSchema(newschema, {replace: true})
    toShare.collections.form.set(form)

  # Update the VolunteersForm schema each time the Form is updated.
  # XXX this should be called something like "eventName-VolunteerForm" XXX
  FormBuilder.Collections.DynamicForms.find({name: "VolunteerForm"}).observe(
    added:   (doc) -> toShare.collections.extendVolunteerForm(doc)
    changed: (doc) -> toShare.collections.extendVolunteerForm(doc)
    removed: (doc) -> toShare.collections.extendVolunteerForm(doc)
  )

  # User duties

  toShare.collections.ShiftSignups = new Mongo.Collection "#{prefix}Volunteers.shiftSignups"
  toShare.collections.ShiftSignups.attachSchema(share.Schemas.ShiftSignups)

  toShare.collections.TaskSignups = new Mongo.Collection "#{prefix}Volunteers.taskSignups"
  toShare.collections.TaskSignups.attachSchema(share.Schemas.TaskSignups)

  toShare.collections.LeadSignups = new Mongo.Collection "#{prefix}Volunteers.leadSignups"
  toShare.collections.LeadSignups.attachSchema(share.Schemas.LeadSignups)

  if Meteor.isClient
    toShare.collections.signupCollections =
      shift: toShare.collections.ShiftSignups
      task: toShare.collections.TaskSignups
      lead: toShare.collections.LeadSignups
    toShare.collections.orgUnitCollections =
      team: toShare.collections.Team
      department: toShare.collections.Department
      division: toShare.collections.Division

  # We need to add 'toShare.collections' to share to include the new additions
  _.extend(share, toShare.collections)

module.exports = toShare
_.extend(share, toShare)
