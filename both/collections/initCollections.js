import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
import { SignupSchema } from './volunteer'
import {
  rotaSchema,
  shiftSchema,
  taskSchema,
  projectSchema,
  leadSchema,
} from './duties'
import { departmentSchema, divisionSchema, teamSchema } from './unit'

checkNpmVersions({ 'simpl-schema': '1.x' }, 'goingnowhere:volunteers')
SimpleSchema.extendOptions(['autoform'])

export const collections = {}
export const schemas = {}

export const initCollections = (eventName) => {
  const prefix = `${eventName}.Volunteers`

  // Org
  collections.team = new Mongo.Collection(`${prefix}.team`)
  collections.team.attachSchema(teamSchema)

  collections.department = new Mongo.Collection(`${prefix}.department`)
  collections.department.attachSchema(departmentSchema)

  collections.division = new Mongo.Collection(`${prefix}.division`)
  collections.division.attachSchema(divisionSchema)

  // duties
  collections.task = new Mongo.Collection(`${prefix}.teamTasks`)
  collections.task.attachSchema(taskSchema)
  if (Meteor.isServer) {
    collections.task.createIndex({ parentId: 1 })
  }

  collections.shift = new Mongo.Collection(`${prefix}.teamShifts`)
  collections.shift.attachSchema(shiftSchema)
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
  collections.project.attachSchema(projectSchema)
  if (Meteor.isServer) {
    collections.project.createIndex({ parentId: 1 })
  }

  collections.lead = new Mongo.Collection(`${prefix}.lead`)
  collections.lead.attachSchema(leadSchema)
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
  collections.signups.attachSchema(SignupSchema)
  schemas.signups = SignupSchema
  if (Meteor.isServer) {
    // we enforce using a unique index that a person cannot sign up twice for the same duty
    collections.signups.createIndex({ userId: 1, shiftId: 1 })
  }

  collections.rotas = new Mongo.Collection(`${prefix}.rotas`)
  collections.rotas.attachSchema(rotaSchema)
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
}
