/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { AutoFormComponents } from 'meteor/abate:autoform-components'
import { Template } from 'meteor/templating'
import moment from 'moment-timezone'

import { ProjectDateInline } from '../components/common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../components/common/ShiftDateInline.jsx'

const share = __coffeescriptShare

Template.teamSignupsList.bindI18nNamespace('goingnowhere:volunteers')
Template.teamSignupsList.onCreated(function onCreated() {
  const template = this
  const teamId = template.data._id
  template.signups = new ReactiveVar([])
  share.templateSub(template, 'ShiftSignups.byTeam', teamId)
  share.templateSub(template, 'TaskSignups.byTeam', teamId)
  share.templateSub(template, 'ProjectSignups.byTeam', teamId)
  share.templateSub(template, 'LeadSignups.byTeam', template.teamId)
  template.autorun(() => {
    if (template.subscriptionsReady()) {
      const sel = { parentId: teamId, status: 'pending' }
      const shifts = share.ShiftSignups.find(sel).map(signup => ({
        ...signup,
        type: 'shift',
        duty: share.TeamShifts.findOne(signup.shiftId),
      }))
      const tasks = share.TaskSignups.find(sel).map(signup => ({
        ...signup,
        type: 'task',
        duty: share.TeamTasks.findOne(signup.shiftId),
      }))
      const projects = share.ProjectSignups.find(sel).map(signup => ({
        ...signup,
        type: 'project',
        duty: share.Projects.findOne(signup.shiftId),
      }))
      const leads = share.LeadSignups.find(sel).map(signup => ({
        ...signup,
        type: 'lead',
        duty: share.Lead.findOne(signup.shiftId),
      }))
      const signups = [
        ...shifts,
        ...tasks,
        ...projects,
        ...leads,
      ].sort((a, b) => a.createdAt && b.createdAt && a.createdAt.getTime() - b.createdAt.getTime())
      template.signups.set(signups)
    }
  })
})

Template.teamSignupsList.helpers({
  ProjectDateInline: () => ProjectDateInline,
  ShiftDateInline: () => ShiftDateInline,
  allSignups() {
    return Template.instance().signups.get()
  },
  /* XXX this does not work. date is undefined because createdAt is not there ... */
  createdAgo(date) { return moment(date).fromNow() },
})

Template.teamSignupsList.events({
  'click [data-action="approve"]': function e(event, template) {
    const type = template.$(event.currentTarget).data('type')
    const signupId = template.$(event.currentTarget).data('signup')
    if (type === 'lead') {
      share.meteorCall(`${type}Signups.confirm`, signupId)
    } else {
      share.meteorCall(`${type}Signups.setStatus`, { id: signupId, status: 'confirmed' })
    }
  },
  'click [data-action="refuse"]': function e(event, template) {
    const type = template.$(event.currentTarget).data('type')
    const signupId = template.$(event.currentTarget).data('signup')
    if (type === 'lead') {
      share.meteorCall(`${type}Signups.refuse`, signupId)
    } else {
      share.meteorCall(`${type}Signups.setStatus`, { id: signupId, status: 'refused' })
    }
  },
  'click [data-action="user-info"]': function e(event, template) {
    const userId = template.$(event.currentTarget).data('id')
    const form = share.VolunteerForm.findOne({ userId })
    const user = Meteor.users.findOne(userId)
    const userform = { formName: 'VolunteerForm', form, user }
    // Lifted straight from NoInfo view, should be replaced by something better
    AutoFormComponents.ModalShowWithTemplate(
      'formBuilderDisplay',
      userform, 'User Form', 'lg',
    )
  },
})

Template.departmentSignupsList.bindI18nNamespace('goingnowhere:volunteers')
Template.departmentSignupsList.onCreated(function onCreated() {
  const template = this
  template.departmentId = this.data._id
  share.templateSub(template, 'LeadSignups.byDepartment', template.departmentId)
})

Template.departmentSignupsList.helpers({
  allSignups: () => {
    const { departmentId } = Template.instance()
    const teams = share.Team.find({ parentId: departmentId }, { _id: 1 }).fetch()
    const teamIds = _.pluck(teams, '_id')
    const sel = { parentId: { $in: teamIds }, status: 'pending' }
    const leads = share.LeadSignups.find(sel).map(signup => ({
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
    share.meteorCall('leadSignups.confirm', signupId)
  },
  'click [data-action="refuse"]': function e(event, template) {
    const signupId = template.$(event.currentTarget).data('signup')
    share.meteorCall('leadSignups.refuse', signupId)
  },
})
