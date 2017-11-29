SingleTeamController = eventName => RouteController.extend({
  waitOn() {return [
    Meteor.subscribe(`${eventName}.Volunteers.team`),
  ]},
  data() {return this.params && this.params._id && this.ready() &&
      coffee.Team.findOne(this.params._id)},
})
