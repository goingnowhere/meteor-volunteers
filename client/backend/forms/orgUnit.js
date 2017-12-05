import { eventName1 } from '../../../api'
import { meteorSub } from '../../../both/global'
import { collections } from '../../../both/collections/initCollections'

let template
Template.orgUnitList.onCreated(function() {
  template = this
  meteorSub(template.data.unitType)
})

Template.orgUnitList.helpers({
  orgUnits: () => collections.orgUnitCollections[template.data.unitType].find(),
  orgUnitView: () => `${template.data.unitType}View-${eventName1.get()}`,
  unitDashboard: () => `unitDashboard-${eventName1.get()}`,
})
