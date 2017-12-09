let share = __coffeescriptShare;

SingleUnitController = eventName => RouteController.extend({
  waitOn() { return [ share.meteorSub('organization') ] },
  data() {
    if (this.params && this.params._id && this.ready()) {
      return share.getOrgUnit(this.params._id)
    }
  },
})
