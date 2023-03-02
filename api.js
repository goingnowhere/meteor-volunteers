import { Meteor } from 'meteor/meteor'
import { Roles } from 'meteor/alanning:roles'
import moment from 'moment-timezone'

import { initMethods } from './both/methods/methods'
import { initCollections } from './both/collections/initCollections'
import { initServices } from './both/services'

import { initServerMethods } from './server/methods'
import { initClient, reactContext } from './client/clientInit'

export * from './both/utils/helpers'
export { useMethodCallData } from './client/utils/useMethodCallData'
export { BookedTable } from './client/components/volunteers/BookedTable.jsx'
export { SignupApproval } from './client/components/teamLeads/SignupApproval.jsx'
export { TeamShiftsTable } from './client/components/teamLeads/TeamShiftsTable.jsx'
export { TeamProjectsTable } from './client/components/teamLeads/TeamProjectsTable.jsx'
export { ShiftDateInline } from './client/components/common/ShiftDateInline.jsx'
export { DutiesListItem } from './client/components/shifts/DutiesListItem.jsx'
export { SignupShiftButtons } from './client/components/shifts/SignupShiftButtons.jsx'
export { SignupsListTeam } from './client/components/volunteers/SignupsListTeam.jsx'
export { SignupsList } from './client/components/shifts/SignupsList.jsx'

export class VolunteersClass {
  /** dontShare is used to start an instance without weird coffeescript global effects */
  constructor(eventName, dontShare) {
    this.eventName = eventName

    const roles = ['admin', 'manager']
    roles.forEach((role) => Roles.createRole(role, { unlessExists: true }))
    // establish a hierarchy among roles
    if (Meteor.isServer) {
      Roles.addRolesToParent('manager', 'admin')
    }

    const { collections, schemas } = initCollections(this.eventName)
    this.schemas = schemas
    this.collections = collections

    this.services = initServices(this)
    // TODO deprecated
    this.auth = this.services.auth

    let methods = {}
    let methodBodies = {}
    // TODO this can most likely be removed but annual rota migration needs to be tested
    if (!dontShare) {
      ({ methodBodies, ...methods } = initMethods(this))
      if (Meteor.isServer) {
        initServerMethods(this)
      }
      if (Meteor.isServer) {
        import('./server/publications')
          .then(({ initPublications }) => initPublications(this))
          .catch(err => console.error('Error importing server publications', err))
      }
    }
    this.methods = methods
    this.methodBodies = methodBodies

    if (Meteor.isClient) {
      initClient()
      this.reactContext = reactContext
    }
  }

  setTimeZone = (timezone) => {
    moment.tz.setDefault(timezone)
    if (Meteor.isClient) {
      // eslint-disable-next-line global-require
      require('meteor/abate:autoform-datetimepicker').setPickerTimezone(timezone)
    }
  }
}
