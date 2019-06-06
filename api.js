/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/piemonkey:roles'
import { initMethods } from './both/methods/methods'
import { getSkillsList, getQuirksList } from './both/collections/unit'

export { BookedTable } from './client/components/volunteers/BookedTable.jsx'

const share = __coffeescriptShare

const initAuthorization = (eventName) => {
  // is the given user manager or admin ?
  share.isManager = (userId = Meteor.userId()) =>
    Roles.userIsInRole(userId, ['manager', 'admin'], eventName)
  // is the given is Manager, or Lead of one of the unitIdList
  share.isManagerOrLead = (userId, unitIdList) =>
    share.isManager(userId) || Roles.userIsInRole(userId, unitIdList, eventName)
  // is the given user a Lead of any team or dept ?
  share.isLead = (userId = Meteor.userId()) =>
    // TODO Get rid of 'user' role?
    Roles.getRolesForUser(userId, eventName).filter(role => role !== 'user').length > 0
}

// TODO migrated from coffeescript, can most likely simplify
export class VolunteersClass {
  constructor(eventName) {
    this.eventName = eventName
    share.initCollections(this.eventName)
    initMethods(this.eventName)
    if (Meteor.isServer) {
      share.initServerMethods(this.eventName)
    }
    initAuthorization(this.eventName)
    if (Meteor.isServer) {
      share.initPublications(this.eventName)
    }
    // Need to wrap functions as are initialised after constructor runs
    this.isManagerOrLead = (...args) => share.isManagerOrLead(...args)
    this.isManager = (...args) => share.isManager(...args)
    this.isLead = (...args) => share.isLead(...args)
    this.teamStats = (...args) => share.TeamStats(...args)
    this.deptStats = (...args) => share.DepartmentStats(...args)

    this.Schemas = share.Schemas
    this.Collections = {
      VolunteerForm: share.VolunteerForm,
      Team: share.Team,
      Division: share.Division,
      Department: share.Department,
      TeamShifts: share.TeamShifts,
      TeamTasks: share.TeamTasks,
      Projects: share.Projects,
      Lead: share.Lead,
      ShiftSignups: share.ShiftSignups,
      ProjectSignups: share.ProjectSignups,
      TaskSignups: share.TaskSignups,
      LeadSignups: share.LeadSignups,
      UnitAggregation: share.UnitAggregation,
      orgUnitCollections: share.orgUnitCollections,
      dutiesCollections: share.dutiesCollections,
      signupCollections: share.signupCollections,
    }
  }

  getSkillsList = getSkillsList

  getQuirksList = getQuirksList

  setTimeZone = (timezone) => {
    share.timezone.set(timezone)
    share.setMethodTimezone(timezone)
    if (Meteor.isClient) {
      // eslint-disable-next-line global-require
      require('meteor/abate:autoform-datetimepicker').setPickerTimezone(timezone)
    }
  }
}
