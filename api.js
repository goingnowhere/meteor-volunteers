/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/piemonkey:roles'
import moment from 'moment-timezone'

import { initMethods } from './both/methods/methods'
import { getSkillsList, getQuirksList } from './both/collections/unit'
import { collections } from './both/collections/initCollections'
import { volunteerFormSchema } from './both/collections/volunteer'
import { deptStats } from './both/stats'

import { initServerMethods } from './server/methods'

export { BookedTable } from './client/components/volunteers/BookedTable.jsx'
export { SignupApproval } from './client/components/teamLeads/SignupApproval.jsx'
export { TeamShiftsTable } from './client/components/teamLeads/TeamShiftsTable.jsx'
export { TeamProjectsTable } from './client/components/teamLeads/TeamProjectsTable.jsx'
export { ShiftDateInline } from './client/components/common/ShiftDateInline.jsx'
export { DutiesListItem } from './client/components/shifts/DutiesListItem.jsx'
export { SignupButtons } from './client/components/shifts/SignupButtons.jsx'

const share = __coffeescriptShare

const initAuthorization = (eventName) => {
  // is the given user manager or admin ?
  share.isManager = (userId = Meteor.userId()) =>
    Roles.userIsInRole(userId, ['manager', 'admin'], eventName)
  // is the given is Manager, or Lead of one of the unitIdList
  share.isManagerOrLead = (userId, unitIdList) =>
    // TODO isLead didn't used to include list, so check if this would break anything then
    // pull these functions together
    share.isManager(userId) || Roles.userIsInRole(userId, unitIdList, eventName)
  // is the given user a Lead of any team or dept ?
  share.isLead = (userId = Meteor.userId(), unitIdList) => {
    if (!unitIdList) {
      // TODO Get rid of 'user' role?
      return Roles.getRolesForUser(userId, eventName).filter((role) => role !== 'user').length > 0
    }
    return Roles.userIsInRole(userId, unitIdList, eventName)
  }
}

// TODO migrated from coffeescript, can most likely simplify
export class VolunteersClass {
  constructor(eventName) {
    this.eventName = eventName
    share.initCollections(this.eventName)
    initMethods(this.eventName)
    if (Meteor.isServer) {
      initServerMethods(this.eventName)
    }
    initAuthorization(this.eventName)
    if (Meteor.isServer) {
      share.initPublications(this.eventName)
    }
    // Need to wrap functions as are initialised after constructor runs
    this.isManagerOrLead = (...args) => share.isManagerOrLead(...args)
    this.isManager = (...args) => share.isManager(...args)
    this.isLead = (...args) => share.isLead(...args)
    this.deptStats = (...args) => deptStats(...args)

    this.schemas = {
      volunteerForm: volunteerFormSchema,
    }
    this.Collections = {
      ...collections,
      VolunteerForm: share.VolunteerForm,
      Team: share.Team,
      Division: share.Division,
      Department: share.Department,
      TeamShifts: share.TeamShifts,
      TeamTasks: share.TeamTasks,
      Projects: share.Projects,
      Lead: share.Lead,
      UnitAggregation: share.UnitAggregation,
    }
  }

  getSkillsList = getSkillsList

  getQuirksList = getQuirksList

  setTimeZone = (timezone) => {
    moment.tz.setDefault(timezone)
    if (Meteor.isClient) {
      // eslint-disable-next-line global-require
      require('meteor/abate:autoform-datetimepicker').setPickerTimezone(timezone)
    }
  }
}
