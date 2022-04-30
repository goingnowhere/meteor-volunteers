import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/alanning:roles'

export const auth = {}

export const initAuth = (eventName) => {
  auth.isManager = (userId = Meteor.userId()) =>
    Roles.userIsInRole(userId, ['manager', 'admin'], eventName)

  auth.isALead = (userId = Meteor.userId()) =>
    // TODO Get rid of 'user' role?
    Roles.getRolesForUser(userId, eventName).filter((role) => role !== 'user').length > 0

  auth.isLead = (userId = Meteor.userId(), unitId) => {
    if (!unitId || unitId instanceof Array) {
      // userIsInRole accepts an array but it's too easy to make data access mistakes that way
      console.warn('Incorrectly checking lead privileges', unitId, new Error())
      return false
    }
    return Roles.userIsInRole(userId, unitId, eventName) || auth.isManager()
  }
}