import SimpleSchema from 'simpl-schema'

share.initCollections = (eventName) ->
  share.eventName = eventName

  prefix = "#{eventName}."

  # duties

  share.TeamTasks = new Mongo.Collection "#{prefix}Volunteers.teamTasks"
  share.TeamTasks.attachSchema(share.Schemas.TeamTasks)

  share.TeamShifts = new Mongo.Collection "#{prefix}Volunteers.teamShifts"
  share.TeamShifts.attachSchema(share.Schemas.TeamShifts)

  share.Lead = new Mongo.Collection "#{prefix}Volunteers.lead"
  share.Lead.attachSchema(share.Schemas.Lead)

  # Orga

  share.Team = new Mongo.Collection "#{prefix}Volunteers.team"
  share.Team.attachSchema(share.Schemas.Team)

  share.Department = new Mongo.Collection "#{prefix}Volunteers.department"
  share.Department.attachSchema(share.Schemas.Department)

  share.Division = new Mongo.Collection "#{prefix}Volunteers.division"
  share.Division.attachSchema(share.Schemas.Division)

  # User Form

  share.VolunteerForm = new Mongo.Collection "#{prefix}Volunteers.volunteerForm"
  share.VolunteerForm.attachSchema(share.Schemas.VolunteerForm)
  share.form = new ReactiveVar(share.VolunteerForm)

  share.extendVolunteerForm = (data) ->
    form = share.form.get()
    schema = new SimpleSchema(share.Schemas.VolunteerForm)
    newschema = schema.extend(FormBuilder.toSimpleSchema(data))
    form.attachSchema(newschema, {replace: true})
    share.form.set(form)

  # Update the VolunteersForm schema each time the Form is updated.
  # XXX this should be called something like "eventName-VolunteerForm" XXX
  FormBuilder.Collections.DynamicForms.find({name: "VolunteerForm"}).observe(
    added:   (doc) -> share.extendVolunteerForm(doc)
    changed: (doc) -> share.extendVolunteerForm(doc)
    removed: (doc) -> share.extendVolunteerForm(doc)
  )

  # User duties

  share.ShiftSignups = new Mongo.Collection "#{prefix}Volunteers.shiftSignups"
  share.ShiftSignups.attachSchema(share.Schemas.ShiftSignups)

  share.TaskSignups = new Mongo.Collection "#{prefix}Volunteers.taskSignups"
  share.TaskSignups.attachSchema(share.Schemas.TaskSignups)

  share.LeadSignups = new Mongo.Collection "#{prefix}Volunteers.leadSignups"
  share.LeadSignups.attachSchema(share.Schemas.LeadSignups)

  # shortcut to recover all related collections more easily
  share.signupCollections =
    shift: share.ShiftSignups
    task: share.TaskSignups
    lead: share.LeadSignups
  share.orgUnitCollections =
    team: share.Team
    department: share.Department
    division: share.Division
  share.dutiesCollections =
    lead: share.Lead
    shift: share.TeamShifts
    task: share.TeamTasks
