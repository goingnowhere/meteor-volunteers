/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import moment from 'moment-timezone'

import { initMethods, methodBodies } from './both/methods/methods'
import { getSkillsList, getQuirksList } from './both/utils/unit'
import { collections, initCollections } from './both/collections/initCollections'
import { volunteerFormSchema } from './both/collections/volunteer'
import { initAuth, auth } from './both/utils/auth'

import { initServerMethods } from './server/methods'
import { initClient } from './client/clientInit'

export { BookedTable } from './client/components/volunteers/BookedTable.jsx'
export { SignupApproval } from './client/components/teamLeads/SignupApproval.jsx'
export { TeamShiftsTable } from './client/components/teamLeads/TeamShiftsTable.jsx'
export { TeamProjectsTable } from './client/components/teamLeads/TeamProjectsTable.jsx'
export { ShiftDateInline } from './client/components/common/ShiftDateInline.jsx'
export { DutiesListItem } from './client/components/shifts/DutiesListItem.jsx'
export { SignupButtons } from './client/components/shifts/SignupButtons.jsx'

const share = __coffeescriptShare

// TODO migrated from coffeescript, can most likely simplify
export class VolunteersClass {
  /** dontShare is used to start an instance without weird coffeescript global effects */
  constructor(eventName, dontShare) {
    this.eventName = eventName
    share.eventName = this.eventName
    initCollections(this.eventName)
    if (!dontShare) {
      initMethods(this.eventName)
      if (Meteor.isServer) {
        initServerMethods(this.eventName)
      }
      initAuth(this.eventName)
      this.auth = auth
      if (Meteor.isServer) {
        share.initPublications(this.eventName)
      }
    }

    this.schemas = {
      volunteerForm: volunteerFormSchema,
    }
    this.Collections = collections
    this.methodBodies = methodBodies

    if (Meteor.isClient) {
      initClient()
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
