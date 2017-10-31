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
    return coffee.ShiftSignups.find({ teamId: this._id }).map(signup => ({
      ...signup,
      shift: coffee.TeamShifts.findOne({ _id: signup.teamId }),
      applicant: Meteor.users.findOne({ _id: signup.userId }),
    }))
  },
  displayName: ({ profile, emails }) =>
    profile.alias || profile.firstName ? fullName(profile) : emails[0].address,
})
