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

// Unfortunately Meteor doesn't like us initialising collections twice but doesn't
// give us a way to clean them up, so incase we create an instance with the same eventName
// twice without restarting, keep a singleton map and reuse.
const allCollections = new Map()
const createCollection = (name) => {
  let collection = allCollections.get(name)
  if (!collection) {
    collection = new Mongo.Collection(name)
    allCollections.set(name, collection)
  }
  return collection
}

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
  collections.team = createCollection(`${prefix}.team`)
  collections.team.attachSchema(schemas.team)

  collections.department = createCollection(`${prefix}.department`)
  collections.department.attachSchema(schemas.department)

  collections.division = createCollection(`${prefix}.division`)
  collections.division.attachSchema(schemas.division)

  // duties
  collections.task = createCollection(`${prefix}.teamTasks`)
  collections.task.attachSchema(schemas.task)
  if (Meteor.isServer) {
    collections.task.createIndex({ parentId: 1 })
  }

  collections.shift = createCollection(`${prefix}.teamShifts`)
  collections.shift.attachSchema(schemas.shift)
  if (Meteor.isServer) {
    collections.shift.createIndex({ parentId: 1 })
    collections.shift.createIndex({ rotaId: 1 })
  }

  // Temporarily re-add to get dashboard working
  if (Meteor.isClient) {
    // Create client-side only collection to reactively aggregate into
    // If preformance is a problem we could aggregate into a collection inside Mongo
    collections.shiftGroups = createCollection(`${prefix}.shiftGroups`)
  }

  collections.project = createCollection(`${prefix}.projects`)
  collections.project.attachSchema(schemas.project)
  if (Meteor.isServer) {
    collections.project.createIndex({ parentId: 1 })
  }

  collections.lead = createCollection(`${prefix}.lead`)
  collections.lead.attachSchema(schemas.lead)
  if (Meteor.isServer) {
    collections.lead.createIndex({ parentId: 1 })
  }

  // Data for the volunteer Form
  collections.volunteerForm = createCollection(`${prefix}.volunteerForm`)
  if (Meteor.isServer) {
    collections.volunteerForm.createIndex({ userId: 1 })
  }

  // User duties
  collections.signups = createCollection(`${prefix}.signups`)
  collections.signups.attachSchema(schemas.signup)
  if (Meteor.isServer) {
    collections.signups.createIndex({ shiftId: 1 })
    collections.signups.createIndex({ userId: 1 })
  }

  collections.rotas = createCollection(`${prefix}.rotas`)
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
