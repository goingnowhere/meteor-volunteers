let share = __coffeescriptShare;

Template.orgUnitList.onCreated(function() {
  template = this
  share.meteorSub(template.data.unitType)
})

Template.orgUnitList.helpers({
  orgUnits: () => share.orgUnitCollections[template.data.unitType].find(),
  orgUnitView: () => {
    return `${template.data.unitType}View-${share.eventName}`;
  },
  unitDashboard: () => `unitDashboard-${share.eventName}`,
})
