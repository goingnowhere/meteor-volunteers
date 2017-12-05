import { collections } from './collections/initCollections'
import { getOrgUnit } from './collections/unit'
import { meteorSub } from './global'

SingleUnitController = eventName => RouteController.extend({
  waitOn() {return [
    meteorSub('organization'),
  ]},
  data() {
    return this.params && this.params._id && this.ready() && getOrgUnit(this.params._id)
  },
})
