import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/alanning:roles'

import { initAuthMixins } from './authMixins'

export const initAuthService = ({ eventName }) => {
  const isManager = (userId = Meteor.userId()) =>
    Roles.userIsInRole(userId, ['manager', 'admin'], eventName)

  const authService = {
    isManager,
    isALead: (userId = Meteor.userId()) =>
      Roles.getRolesForUser(userId, eventName).length > 0,

    isLead: (userId = Meteor.userId(), unitId) => {
      if (!unitId || unitId instanceof Array) {
      // userIsInRole accepts an array but it's too easy to make data access mistakes that way
        console.warn('Incorrectly checking lead privileges', unitId, new Error())
        return false
      }
      return Roles.userIsInRole(userId, unitId, eventName) || isManager()
    },
  }

  const mixins = initAuthMixins(authService)

  return {
    ...authService,
    mixins,
  }
}
