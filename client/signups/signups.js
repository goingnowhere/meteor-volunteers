let share = __coffeescriptShare;

Template.teamSignupsList.onCreated(function () {
  const template = this;
  template.teamId = this.data._id
  share.templateSub(template,"ShiftSignups.byTeam",template.teamId)
  share.templateSub(template,"TaskSignups.byTeam",template.teamId)
  share.templateSub(template,"LeadSignups.byTeam",template.teamId)
})

Template.teamSignupsList.helpers({
  allSignups() {
    teamId = Template.instance().teamId
    const shifts = share.ShiftSignups.find({ parentId: teamId , status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'shift',
        duty: share.TeamShifts.findOne(signup.shiftId)
      }))
    const tasks = share.TaskSignups.find({ parentId: teamId, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'task',
        duty: share.TeamTasks.findOne(signup.shiftId)
      }))
    const leads = share.LeadSignups.find({ parentId: teamId, status: 'pending' }, {sort: {createdAt: -1}})
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
