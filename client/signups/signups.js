let share = __coffeescriptShare;

Template.teamSignupsList.bindI18nNamespace('abate:volunteers');
Template.teamSignupsList.onCreated(function () {
  const template = this;
  template.teamId = this.data._id
  share.templateSub(template,"ShiftSignups.byTeam",template.teamId)
  share.templateSub(template,"TaskSignups.byTeam",template.teamId)
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
    return [
      ...shifts,
      ...tasks,
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

Template.departmentSignupsList.bindI18nNamespace('abate:volunteers');
Template.departmentSignupsList.onCreated(function () {
  const template = this;
  template.departmentId = this.data._id
  share.templateSub(template,"LeadSignups.byDepartment",template.departmentId)
})

Template.departmentSignupsList.helpers({
  allSignups: () => {
    departmentId = Template.instance().departmentId
    teamIds = share.Team.find({parentId: departmentId}).map((t) => { return t._id })
    const leads = share.LeadSignups.find(
        { parentId: {$in: teamIds}, status: 'pending' }, {sort: {createdAt: -1}}
      ).map(signup => ({
          ...signup,
          type: 'lead',
          duty: share.Lead.findOne(signup.shiftId)
      })).sort((a, b) => {
        return a.createdAt && b.createdAt && a.createdAt.getTime() - b.createdAt.getTime()
    })
    return leads
  }
})

Template.departmentSignupsList.events({
  'click [data-action="approve"]'(event) {
    const signupId = $(event.target).data('signup')
    share.meteorCall(`leadSignups.confirm`, signupId)
  },
  'click [data-action="refuse"]'(event) {
    const signupId = $(event.target).data('signup')
    share.meteorCall(`leadSignups.refuse`, signupId)
  },
})
