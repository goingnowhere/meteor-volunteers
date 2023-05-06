import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/alanning:roles'

import { initAuthMixins } from './authMixins'

const MANAGER_ROLES = ['manager', 'admin']

export const initAuthService = ({ eventName, collections }) => {
  const isManager = (userId = Meteor.userId()) =>
    Roles.userIsInRole(userId, MANAGER_ROLES, eventName)

  const authService = {
    isManager,
    isALead: (userId = Meteor.userId()) =>
      Roles.getRolesForUser(userId, eventName).length > 0,
    getLeadUnitIds: (userId = Meteor.userId()) =>
      Roles.getRolesForUser(userId, eventName)
        .filter((role) => !MANAGER_ROLES.includes(role)),

    isLead: (userId = Meteor.userId(), unitId) => {
      if (!unitId || unitId instanceof Array) {
      // userIsInRole accepts an array but it's too easy to make data access mistakes that way
        console.warn('Incorrectly checking lead privileges', unitId, new Error())
        return false
      }
      return Roles.userIsInRole(userId, unitId, eventName) || isManager()
    },
    // FIXME Should make a role for this to avoid this mess
    isNoInfo: () => {
      const noInfo = collections.team.findOne({ name: 'NoInfo' })
      const wh = collections.team.findOne({ name: 'Werkhaüs' })
      return ((noInfo) && authService.isLead(Meteor.userId(), noInfo._id))
        || ((wh) && authService.isLead(Meteor.userId(), wh._id))
    },
  }

  const mixins = initAuthMixins(authService)

  return {
    ...authService,
    mixins,
  }
}
