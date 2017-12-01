import { collections } from './collections/initCollections'

SingleTeamController = eventName => RouteController.extend({
  waitOn() {return [
    Meteor.subscribe(`${eventName}.Volunteers.team`),
  ]},
  data() {return this.params && this.params._id && this.ready() &&
      collections.Team.findOne(this.params._id)},
})
