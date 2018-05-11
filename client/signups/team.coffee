import { Chart } from 'chart.js'

import Moment from 'moment'
import 'moment-timezone'
import { extendMoment } from 'moment-range'

moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

commonEvents =
  'click [data-action="un-enroll"]': (event,template) ->
    userId = $(event.currentTarget).data('userid')
    shiftId = $(event.currentTarget).data('shiftid')
    type = $(event.currentTarget).data('type')
    switch type
      when 'shift'
        shift = share.ShiftSignups.findOne({ userId, shiftId })
        share.meteorCall "shiftSignups.remove", shift._id
      when 'project'
        shift = share.ProjectSignups.findOne({ userId, shiftId })
        share.meteorCall "projectSignups.remove", shift._id
  'click [data-action="edit"]': (event,template) ->
    id = $(event.currentTarget).data('id')
    type = $(event.currentTarget).data('type')
    collection = share.dutiesCollections[type]
    shift = collection.findOne(id)
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection}, data: shift}, "", 'lg')
  'click [data-action="delete"]': (event,template) ->
    id = $(event.currentTarget).data('id')
    type = $(event.currentTarget).data('type')
    switch type
      when 'shift'
        share.meteorCall "teamShifts.remove", id
      when 'project'
        share.meteorCall "projects.remove", id
      when 'task'
        share.meteorCall "teamTasks.remove", id
  'click [data-action="add_date"]': (event,template) ->
    id = $(event.currentTarget).data('id')
    type = $(event.currentTarget).data('type')
    collection = share.dutiesCollections[type]
    shift = collection.findOne(id)
    delete shift._id
    delete shift.start
    delete shift.end
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      { form: {
        collection,
        hiddenFields:"description, priority, policy, title"
        }, data: shift
      }, shift.title)
  'click [data-action="edit_group"]': (event,template) ->
    id = $(event.currentTarget).data('id')
    type = $(event.currentTarget).data('type')
    collection = share.dutiesCollections[type]
    shift = collection.findOne(id)
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate", {
      form: {
        collection,
        omitFields:"start, end, staffing, min, max, estimatedTime, dueDate",
        update: {
          method: "#{collection._name}.group.update",
          label: i18n.__("abate:volunteers","update_group"),
        },
      },
      data: shift,
    }, shift.title)

Template.teamShiftsTable.bindI18nNamespace('abate:volunteers')
Template.teamShiftsTable.onCreated () ->
  template = this
  teamId = template.data._id
  share.templateSub(template,"ShiftSignups.byTeam",teamId)
  # share.templateSub(template,"LeadSignups.byTeam",teamId)
  # share.templateSub(template,"TaskSignups.byTeam",teamId)
  # share.templateSub(template,"ProjectSignups.byTeam",teamId)
  template.shifts = new ReactiveVar([])
  template.grouping = new ReactiveVar(new Set())
  template.autorun () ->
    if template.subscriptionsReady()
      sel = {parentId: teamId}
      date = Template.currentData().date
      if date
        startOfDay = moment(date).startOf('day')
        endOfDay = moment(date).endOf('day')
        sel =
          $and: [
            sel,
            {
              $and: [
                { end: { $gte: startOfDay.toDate() } },
                { start: { $lte: endOfDay.toDate() } },
              ]
            }
          ]
      shifts = share.getShifts(sel)
      template.shifts.set(shifts)

Template.teamShiftsTable.helpers
  'groupedShifts': () ->
    _.chain(Template.instance().shifts.get())
    .groupBy('groupId')
    .map((v,k) ->
      title: v[0].title
      first: v[0]
      class: "family-#{k}"
      shifts: v
    ).value()

Template.teamShiftsTable.events commonEvents

Template.teamProjectsTable.bindI18nNamespace('abate:volunteers')
Template.teamProjectsTable.onCreated () ->
  template = this
  template.teamId = template.data._id
  share.templateSub(template,"ProjectSignups.byTeam",template.teamId)

Template.teamProjectsTable.helpers
  allProjects: () ->
    share.Projects.find({parentId: Template.instance().teamId}).map((project) ->
      signups = share.ProjectSignups.find({shiftId: project._id, status: 'confirmed'}).fetch()
      _.extend(project,{volunteers: signups, confirmed: signups.length })
      )

Template.teamProjectsTable.events commonEvents

Template.projectStaffingChart.bindI18nNamespace('abate:volunteers')
Template.projectStaffingChart.helpers
  stackedBarData: (project) ->
    confirmedSignups = Template.currentData().confirmedSignups
    signupData = _.extend(share.projectSignupsConfirmed(project),{_id:project._id})
    if confirmedSignups
      signupData = _.extend(signupData, {
        confirmed: confirmedSignups,
        needed: signupData.needed.map((need, index) -> Math.max(0,need - confirmedSignups[index])),
      })
    signupData

drawStakedBar = (props) ->
  barData = props.barData
  datasets = [{ label: "needed", data: barData.needed, backgroundColor: '#ffe94D' }]
  unless props.hideConfirmed
    datasets.unshift({ label: "confirmed", data: barData.confirmed, backgroundColor: '#D6E9C6' })
  data =
    labels: barData.days.map((t) -> moment(t).format("MMM Do"))
    datasets: datasets
  options =
    responsive: true,
    # XXX canvas are not fully responsive ...
    # maintainAspectRatio: false,
    scales:
      xAxes: [{ stacked: true }],
      yAxes: [{ stacked: true }]
  ctx = $("#StackedBar-#{barData._id}").get(0).getContext('2d')
  new Chart(ctx,{type: 'bar', data: data, options: options})

Template.stackedBar.onRendered () ->
  template = this
  template.autorun () ->
    drawStakedBar(Template.currentData())
