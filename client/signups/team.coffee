import { Chart } from 'chart.js'
import Moment from 'moment'

commonEvents =
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
        share.meteorCall "Project.remove", id
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
      {form:{collection}, data: shift})

Template.teamShiftsTable.bindI18nNamespace('abate:volunteers')
Template.teamShiftsTable.onCreated () ->
  template = this
  teamId = template.data._id
  share.templateSub(template,"ShiftSignups.byTeam",teamId)
  share.templateSub(template,"LeadSignups.byTeam",teamId)
  share.templateSub(template,"TaskSignups.byTeam",teamId)
  share.templateSub(template,"ProjectSignups.byTeam",teamId)
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
  share.templateSub(template,"ProjectSignups.byTeam",teamId)

Template.teamProjectsTable.helpers
  allProjects: () ->
    share.Projects.find({parentId: Template.instance().teamId})

Template.teamProjectsTable.events commonEvents

Template.projectStaffingChart.bindI18nNamespace('abate:volunteers')
Template.projectStaffingChart.helpers
  stackedBarData: (project) ->
    confirmedSignups = Template.currentData().confirmedSignups
    signupData = _.extend(share.projectSignupsConfirmed(project),{_id:project._id})
    if confirmedSignups
      signupData = _.extend(signupData, {
        confirmed: confirmedSignups,
        needed: signupData.needed.map((need, index) -> need - confirmedSignups[index]),
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
