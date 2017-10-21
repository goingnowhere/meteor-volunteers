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

  # User

  share.VolunteerForm = new Mongo.Collection "#{prefix}Volunteers.volunteerForm"
  share.VolunteerForm.attachSchema(share.Schemas.VolunteerForm)

  share.ShiftSignups = new Mongo.Collection "#{prefix}Volunteers.shiftSignups"
  share.ShiftSignups.attachSchema(share.Schemas.ShiftSignups)

  share.TaskSignups = new Mongo.Collection "#{prefix}Volunteers.taskSignups"
  share.TaskSignups.attachSchema(share.Schemas.TaskSignups)

  if Meteor.isClient
    # this collection is used in client/frontend/volunteer.coffee
    share.signupCollections =
      shift: share.ShiftSignups
      task: share.TaskSignups
