import SimpleSchema from 'simpl-schema'
import { initCollections } from './initCollections'

share.initCollections = (eventName) ->
  share.eventName = eventName

  prefix = "#{eventName}."

  # Used to store stats but doesn't seem to cache so may not be needed
  share.UnitAggregation = new Mongo.Collection "#{prefix}Volunteers.unitAggregation"
  
  # duties
  share.TeamTasks = new Mongo.Collection "#{prefix}Volunteers.teamTasks"
  share.TeamTasks.attachSchema(share.Schemas.TeamTasks)
  if Meteor.isServer
    share.TeamTasks._ensureIndex( { parentId: 1 } )

  share.TeamShifts = new Mongo.Collection "#{prefix}Volunteers.teamShifts"
  share.TeamShifts.attachSchema(share.Schemas.TeamShifts)
  if Meteor.isServer
    share.TeamShifts._ensureIndex( { parentId: 1 } )

  if Meteor.isClient
    # Create client-side only collection to reactively aggregate into
    # If preformance is a problem we could aggregate into a collection inside Mongo
    share.shiftGroups = new Mongo.Collection "#{prefix}Volunteers.shiftGroups"

  share.Projects = new Mongo.Collection "#{prefix}Volunteers.projects"
  share.Projects.attachSchema(share.Schemas.Projects)
  if Meteor.isServer
    share.Projects._ensureIndex( { parentId: 1 } )

  share.Lead = new Mongo.Collection "#{prefix}Volunteers.lead"
  share.Lead.attachSchema(share.Schemas.Lead)
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
