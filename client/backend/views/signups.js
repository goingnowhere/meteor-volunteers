import { templateSub, meteorCall } from '../../../both/global'
import { collections } from '../../../both/collections/initCollections'

Template.teamSignupsList.onCreated(function () {
  const template = this;
  templateSub(template,"users")
  templateSub(template,"allDuties.byTeam",this.data.unit._id)
})

Template.teamSignupsList.helpers({
  allSignups() {
    const shifts = collections.ShiftSignups.find({ parentId: this.unit._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'shift',
        duty: collections.TeamShifts.findOne(signup.shiftId)
      }))
    const tasks = collections.TaskSignups.find({ parentId: this.unit._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'task',
        duty: collections.TeamTasks.findOne(signup.shiftId)
      }))
    const leads = collections.LeadSignups.find({ parentId: this.unit._id, status: 'pending' }, {sort: {createdAt: -1}})
      .map(signup => ({
        ...signup,
        type: 'lead',
        duty: collections.Lead.findOne(signup.shiftId)
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
      meteorCall(`${type}Signups.confirm`, signupId)
    } else {
      const signup = {_id: signupId, modifier: {$set: {status: 'confirmed'}}}
      meteorCall(`${type}Signups.update`, signup)
    }
  },
  'click [data-action="refuse"]'(event) {
    const type = $(event.target).data('type')
    const signupId = $(event.target).data('signup')
    if (type === 'lead') {
      meteorCall(`${type}Signups.refuse`, signupId)
    } else {
      const signup = {_id: signupId, modifier: {$set: {status: 'refused'}}}
      meteorCall(`${type}Signups.update`, signup)
    }
  },
})
