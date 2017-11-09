Template.teamSignupsList.onCreated(function () {
  // FIXME need to somehow make 'test' passed in rather than hard-coded
  this.subscribe('test.Volunteers.users')
  this.subscribe("test.Volunteers.teamTasks.backend", this.data._id)
  this.subscribe("test.Volunteers.taskSignups")
  this.subscribe("test.Volunteers.teamShifts.backend", this.data._id)
  this.subscribe("test.Volunteers.shiftSignups")
})

const fullName = ({ firstName, lastName }) => `${firstName} ${lastName}`

Template.teamSignupsList.helpers({
  allSignups() {
    return coffee.ShiftSignups.find({ teamId: this._id, status: 'pending' }).map(signup => ({
      ...signup,
      shift: coffee.TeamShifts.findOne({ parentId: signup.teamId }),
      applicant: Meteor.users.findOne({ _id: signup.userId }),
    }))
  },
  displayName: ({ profile, emails }) =>
    profile.alias || profile.firstName ? fullName(profile) : emails[0].address,
  shiftDate: ({ start, end }) =>
    `${moment(start).format('ddd DD MMM HH:mm')} - ${moment(end).format('HH:mm')}`,
})

Template.teamSignupsList.events({
  'click [data-action="approve"]'(event) {
    const signupId = $(event.target).data('signup')
    const signup = {_id: signupId, modifier: {$set: {status: 'confirmed'}}}
    coffee.meteorCall('shiftSignups.update', signup)
  },
  'click [data-action="reject"]'(event) {
    const signupId = $(event.target).data('signup')
    const signup = {_id: signupId, modifier: {$set: {status: 'refused'}}}
    coffee.meteorCall('shiftSignups.update', signup)
  },
})
