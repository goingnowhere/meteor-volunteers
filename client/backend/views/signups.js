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
    const shifts = coffee.ShiftSignups.find({ teamId: this._id, status: 'pending' })
      .map(signup => ({
        ...signup,
        type: 'shift',
        duty: coffee.TeamShifts.findOne({ parentId: signup.teamId }),
        applicant: Meteor.users.findOne({ _id: signup.userId }),
      }))
    const tasks = coffee.TaskSignups.find({ teamId: this._id, status: 'pending' })
      .map(signup => ({
        ...signup,
        type: 'task',
        duty: coffee.TeamTasks.findOne({ parentId: signup.teamId }),
        applicant: Meteor.users.findOne({ _id: signup.userId }),
      }))
    // TODO add a 'signup date' to signups and sort by this
    return shifts.concat(tasks)
  },
  displayName: ({ profile, emails }) =>
    profile.alias || profile.firstName ? fullName(profile) : emails[0].address,
  dutyDate: (type, { start, end, dueDate }) => type === 'shift' ?
    `${moment(start).format('ddd DD MMM HH:mm')} - ${moment(end).format('HH:mm')}`
    : moment(dueDate).format('ddd DD MMM HH:mm'),
})

Template.teamSignupsList.events({
  'click [data-action="approve"]'(event) {
    const type = $(event.target).data('type')
    const signupId = $(event.target).data('signup')
    const signup = {_id: signupId, modifier: {$set: {status: 'confirmed'}}}
    coffee.meteorCall(`${type}Signups.update`, signup)
  },
  'click [data-action="reject"]'(event) {
    const type = $(event.target).data('type')
    const signupId = $(event.target).data('signup')
    const signup = {_id: signupId, modifier: {$set: {status: 'refused'}}}
    coffee.meteorCall(`${type}Signups.update`, signup)
  },
})
