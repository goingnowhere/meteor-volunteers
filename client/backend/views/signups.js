Template.teamSignupsList.onCreated(function () {
  const template = this;
  coffee.templateSub(template,"users")
  coffee.templateSub(template,"teamTasks.backend",this.data._id)
  coffee.templateSub(template,"teamShifts.backend",this.data._id)
  coffee.templateSub(template,"taskSignups")
  coffee.templateSub(template,"shiftSignups")
})

Template.teamSignupsList.helpers({
  allSignups() {
    const shifts = coffee.ShiftSignups.find({ teamId: this._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'shift',
        duty: coffee.TeamShifts.findOne({ parentId: signup.teamId })
      }))
    const tasks = coffee.TaskSignups.find({ teamId: this._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'task',
        duty: coffee.TeamTasks.findOne({ parentId: signup.teamId })
      }))
    return shifts.concat(tasks)
  }
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
