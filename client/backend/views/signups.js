let share = __coffeescriptShare;

Template.teamSignupsList.onCreated(function () {
  const template = this;
  share.templateSub(template,"users")
  share.templateSub(template,"allDuties.byTeam",this.data.unit._id)
})

Template.teamSignupsList.helpers({
  allSignups() {
    const shifts = share.ShiftSignups.find({ parentId: this.unit._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'shift',
        duty: share.TeamShifts.findOne(signup.shiftId)
      }))
    const tasks = share.TaskSignups.find({ parentId: this.unit._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'task',
        duty: share.TeamTasks.findOne(signup.shiftId)
      }))
    const leads = share.LeadSignups.find({ parentId: this.unit._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'lead',
        duty: share.Lead.findOne(signup.shiftId)
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
    if (type === 'lead') {
      share.meteorCall(`${type}Signups.confirm`, signupId)
    } else {
      const signup = {_id: signupId, modifier: {$set: {status: 'confirmed'}}}
      share.meteorCall(`${type}Signups.update`, signup)
    }
  },
  'click [data-action="refuse"]'(event) {
    const type = $(event.target).data('type')
    const signupId = $(event.target).data('signup')
    if (type === 'lead') {
      share.meteorCall(`${type}Signups.refuse`, signupId)
    } else {
      const signup = {_id: signupId, modifier: {$set: {status: 'refused'}}}
      share.meteorCall(`${type}Signups.update`, signup)
    }
  },
})
