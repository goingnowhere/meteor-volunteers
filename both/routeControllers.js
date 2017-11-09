SingleTeamController = eventName => RouteController.extend({
  waitOn() {return [
    Meteor.subscribe(`${eventName}.Volunteers.team`),
    // TODO remove below with proper roles
    Meteor.subscribe(`${eventName}.Volunteers.lead`),
    Meteor.subscribe(`${eventName}.Volunteers.department`),
  ]},
  data() {return this.params && this.params._id && this.ready() &&
      coffee.Team.findOne(this.params._id)},
})
