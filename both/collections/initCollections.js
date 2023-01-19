import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
import { initVolunteerSchemas } from './schemas/volunteer'
import { initDutySchemas } from './schemas/duties'
import { initUnitSchemas } from './schemas/unit'
import { initCollectionUtils } from './utils'

checkNpmVersions({ 'simpl-schema': '1.x' }, 'goingnowhere:volunteers')
SimpleSchema.extendOptions(['autoform'])

export const initCollections = (eventName) => {
  const collections = {}
  const prefix = `${eventName}.Volunteers`

  const utils = initCollectionUtils(collections)
  collections.utils = utils
  const unitSchemas = initUnitSchemas(utils)
  const volunteerSchemas = initVolunteerSchemas(utils)
  const dutySchemas = initDutySchemas()
  const schemas = {
    ...unitSchemas,
    ...volunteerSchemas,
    ...dutySchemas,
  }

  // Org
  collections.team = new Mongo.Collection(`${prefix}.team`)
  collections.team.attachSchema(schemas.team)

  collections.department = new Mongo.Collection(`${prefix}.department`)
  collections.department.attachSchema(schemas.department)

  collections.division = new Mongo.Collection(`${prefix}.division`)
  collections.division.attachSchema(schemas.division)

  // duties
  collections.task = new Mongo.Collection(`${prefix}.teamTasks`)
  collections.task.attachSchema(schemas.task)
  if (Meteor.isServer) {
    collections.task.createIndex({ parentId: 1 })
  }

  collections.shift = new Mongo.Collection(`${prefix}.teamShifts`)
  collections.shift.attachSchema(schemas.shift)
  if (Meteor.isServer) {
    collections.shift.createIndex({ parentId: 1 })
    collections.shift.createIndex({ rotaId: 1 })
  }

  // Temporarily re-add to get dashboard working
  if (Meteor.isClient) {
    // Create client-side only collection to reactively aggregate into
    // If preformance is a problem we could aggregate into a collection inside Mongo
    collections.shiftGroups = new Mongo.Collection(`${prefix}.shiftGroups`)
  }

  collections.project = new Mongo.Collection(`${prefix}.projects`)
  collections.project.attachSchema(schemas.project)
  if (Meteor.isServer) {
    collections.project.createIndex({ parentId: 1 })
  }

  collections.lead = new Mongo.Collection(`${prefix}.lead`)
  collections.lead.attachSchema(schemas.lead)
  if (Meteor.isServer) {
    collections.lead.createIndex({ parentId: 1 })
  }

  // Data for the volunteer Form
  collections.volunteerForm = new Mongo.Collection(`${prefix}.volunteerForm`)
  if (Meteor.isServer) {
    collections.volunteerForm.createIndex({ userId: 1 })
  }

  // User duties
  collections.signups = new Mongo.Collection(`${prefix}.signups`)
  collections.signups.attachSchema(schemas.signup)
  if (Meteor.isServer) {
    // we enforce using a unique index that a person cannot sign up twice for the same duty
    collections.signups.createIndex({ userId: 1, shiftId: 1 })
  }

  collections.rotas = new Mongo.Collection(`${prefix}.rotas`)
  collections.rotas.attachSchema(schemas.rota)
  if (Meteor.isServer) {
    collections.rotas.createIndex({ parentId: 1 })
  }

  // shortcut to recover all related collections more easily
  collections.orgUnitCollections = {
    team: collections.team,
    department: collections.department,
    division: collections.division,
  }
  collections.dutiesCollections = {
    lead: collections.lead,
    shift: collections.shift,
    task: collections.task,
    project: collections.project,
  }

  return { collections, schemas }
}
