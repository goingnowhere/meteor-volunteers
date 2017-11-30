Template.teamSignupsList.onCreated(function () {
  const template = this;
  coffee.templateSub(template,"users")
  coffee.templateSub(template,"allDuties.byTeam",this.data._id)
})

Template.teamSignupsList.helpers({
  allSignups() {
    const shifts = coffee.ShiftSignups.find({ parentId: this._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'shift',
        duty: coffee.TeamShifts.findOne(signup.shiftId)
      }))
    const tasks = coffee.TaskSignups.find({ parentId: this._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'task',
        duty: coffee.TeamTasks.findOne(signup.shiftId)
      }))
    const leads = coffee.LeadSignups.find({ parentId: this._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'lead',
        duty: coffee.Lead.findOne(signup.shiftId)
      }))
    return [
      ...shifts,
      ...tasks,
      ...leads,
    ].sort((a, b) => a.createdAt && b.createdAt && a.createdAt.getTime() - b.createdAt.getTime())
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
