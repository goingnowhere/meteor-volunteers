/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
import { SignupSchema } from './volunteer'

checkNpmVersions({ 'simpl-schema': '1.x' }, 'goingnowhere:volunteers')
SimpleSchema.extendOptions(['autoform'])

const share = __coffeescriptShare

export const collections = {}
export const schemas = {}

export const initCollections = (eventName) => {
  // User duties
  collections.signups = new Mongo.Collection(`${eventName}.Volunteers.signups`)
  collections.signups.attachSchema(SignupSchema)
  schemas.signups = SignupSchema
  if (Meteor.isServer) {
    // we enforce using a unique index that a person cannot sign up twice for the same duty
    collections.signups._ensureIndex({ userId: 1, shiftId: 1 })
  }

  // shortcut to recover all related collections more easily
  collections.orgUnitCollections = {
    team: share.Team,
    department: share.Department,
    division: share.Division,
  }
  collections.dutiesCollections = {
    lead: share.Lead,
    shift: share.TeamShifts,
    task: share.TeamTasks,
    project: share.Projects,
  }
}
