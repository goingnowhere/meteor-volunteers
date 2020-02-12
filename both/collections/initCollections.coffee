import SimpleSchema from 'simpl-schema'
import { shiftSchema, taskSchema, projectSchema, leadSchema } from './duties'
import { initCollections } from './initCollections'

share.initCollections = (eventName) ->
  share.eventName = eventName

  prefix = "#{eventName}."

  # Used to store stats but doesn't seem to cache so may not be needed
  share.UnitAggregation = new Mongo.Collection "#{prefix}Volunteers.unitAggregation"
  
  # duties
  share.TeamTasks = new Mongo.Collection "#{prefix}Volunteers.teamTasks"
  share.TeamTasks.attachSchema(taskSchema)
  if Meteor.isServer
    share.TeamTasks._ensureIndex( { parentId: 1 } )

  share.TeamShifts = new Mongo.Collection "#{prefix}Volunteers.teamShifts"
  share.TeamShifts.attachSchema(shiftSchema)
  if Meteor.isServer
    share.TeamShifts._ensureIndex( { parentId: 1 } )
    share.TeamShifts._ensureIndex( { rotaId: 1 } )

  share.Projects = new Mongo.Collection "#{prefix}Volunteers.projects"
  share.Projects.attachSchema(projectSchema)
  if Meteor.isServer
    share.Projects._ensureIndex( { parentId: 1 } )

  share.Lead = new Mongo.Collection "#{prefix}Volunteers.lead"
  share.Lead.attachSchema(leadSchema)
  if Meteor.isServer
    share.Lead._ensureIndex( { parentId: 1 } )

  # Orga

  share.Team = new Mongo.Collection "#{prefix}Volunteers.team"
  share.Team.attachSchema(share.Schemas.Team)

  share.Department = new Mongo.Collection "#{prefix}Volunteers.department"
  share.Department.attachSchema(share.Schemas.Department)

  share.Division = new Mongo.Collection "#{prefix}Volunteers.division"
  share.Division.attachSchema(share.Schemas.Division)

  # User Form

  # Data for the volunteer Form
  share.VolunteerForm = new Mongo.Collection "#{prefix}Volunteers.volunteerForm"
  if Meteor.isServer
    share.VolunteerForm._ensureIndex( { userId: 1 } )

  # migrate to JS:
  initCollections(eventName)
