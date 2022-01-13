import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/alanning:roles'

export const auth = {}

export const initAuth = (eventName) => {
  auth.isManager = (userId = Meteor.userId()) =>
    Roles.userIsInRole(userId, ['manager', 'admin'], eventName)

  auth.isLead = (userId = Meteor.userId(), unitIdList) => {
    if (!unitIdList) {
      // TODO Get rid of 'user' role?
      return Roles.getRolesForUser(userId, eventName).filter((role) => role !== 'user').length > 0
    }
    return Roles.userIsInRole(userId, unitIdList, eventName) || auth.isManager()
  }
}
