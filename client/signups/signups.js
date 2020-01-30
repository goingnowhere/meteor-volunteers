/* globals __coffeescriptShare */
import { Template } from 'meteor/templating'

import { collections } from '../../both/collections/initCollections'

const share = __coffeescriptShare

Template.departmentSignupsList.bindI18nNamespace('goingnowhere:volunteers')
Template.departmentSignupsList.onCreated(function onCreated() {
  const template = this
  template.departmentId = this.data._id
  share.templateSub(template, 'Signups.byDept', template.departmentId, 'lead')
})

Template.departmentSignupsList.helpers({
  allSignups: () => {
    const { departmentId } = Template.instance()
    const teams = share.Team.find({ parentId: departmentId }, { _id: 1 }).fetch()
    const teamIds = _.pluck(teams, '_id')
    const sel = { parentId: { $in: teamIds }, status: 'pending', type: 'lead' }
    const leads = collections.signups.find(sel).map(signup => ({
      ...signup,
      type: 'lead',
      unit: share.Team.findOne(signup.parentId),
      duty: share.Lead.findOne(signup.shiftId),
    })).sort((a, b) => a.createdAt && b.createdAt && a.createdAt.getTime() - b.createdAt.getTime())
    return leads
  },
})

Template.departmentSignupsList.events({
  'click [data-action="approve"]': function e(event, template) {
    const signupId = template.$(event.currentTarget).data('signup')
    share.meteorCall('signups.confirm', signupId)
  },
  'click [data-action="refuse"]': function e(event, template) {
    const signupId = template.$(event.currentTarget).data('signup')
    share.meteorCall('signups.refuse', signupId)
  },
})
