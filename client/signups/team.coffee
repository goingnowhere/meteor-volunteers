import { Chart } from 'chart.js'

import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

import { projectSignupsConfirmed } from '../../both/stats'
import { ProjectDateInline } from '../components/common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../components/common/ShiftDateInline.jsx'

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
    shift = _.omit(collection.findOne(id),'_id','start','end')
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      { form: {
        collection,
        hiddenFields:"description, priority, policy, title"
        }, data: shift
      }, shift.title)
  'click [data-action="edit_group"]': (event,template) ->
    template.shiftUpdateDep.changed()
    id = $(event.currentTarget).data('id')
    type = $(event.currentTarget).data('type')
    collection = share.dutiesCollections[type]
    protoShift = collection.findOne(id)
    protoShiftFiltered = _.pick(protoShift,
      'title', 'description',
      'priority', 'policy', 'groupId', 'parentId')
    shiftStartDay = moment(protoShift.start).startOf('day').toDate()
    shiftStartNextDay = moment(protoShift.start).add(1,'day').startOf('day').toDate()
    shiftEndDay = moment(protoShift.start).endOf('day').toDate()
    protoDayShifts = collection.find({
      groupId: protoShift.groupId,
      start: { $gte: shiftStartDay , $lt: shiftStartNextDay }
    }).map(({min, max, start, end, rotaId}) ->
      startTime = moment(start).format('HH:mm')
      endTime = moment(end).format('HH:mm')
      {startTime, endTime, min, max, rotaId}
    )
    minDay = collection.find(
      {groupId: protoShift.groupId},
      {sort: { start: 1}, limit:1}).fetch()[0]
    maxDay = collection.find(
      {groupId: protoShift.groupId},
      {sort: { start: -1 }, limit: 1}).fetch()[0]

    AutoFormComponents.ModalShowWithTemplate('addShiftGroup',
      _.extend(protoShiftFiltered,{
        _id: "fake",
        start: minDay.start,
        end: maxDay.start,
        shifts: protoDayShifts,
        oldshifts: protoDayShifts})
    , protoShift.title)
  'click [data-action="delete_group"]': (event,template) ->
    groupId = $(event.currentTarget).data('groupid')
    parentId = $(event.currentTarget).data('parentid')
    share.meteorCall "teamShifts.group.remove", {groupId, parentId}

Template.teamShiftsRota.bindI18nNamespace('goingnowhere:volunteers')
Template.teamShiftsRota.onCreated () ->
  template = this
  teamId = template.data._id
  template.shifts = new ReactiveVar([])
  template.grouping = new ReactiveVar(new Set())
  template.shiftUpdateDep = new Tracker.Dependency
  share.templateSub(template,"ShiftSignups.byTeam",teamId)
  template.autorun () ->
    if template.subscriptionsReady()
      sel = {parentId: teamId}
      template.shifts.set(share.getShifts(sel))

Template.teamShiftsRota.helpers
  'groupedShifts': () ->
    _.chain(Template.instance().shifts.get())
    .map((s) -> _.extend(s,{ startday: moment(s.start).format("MM-DD-YY")}) )
    .groupBy('startday')
    .map((v1,k1) ->
      day: k1
      shifts: _.chain(v1)
        .groupBy('groupId')
        .map((v,k) ->
          title: v[0].title
          groupId: k
          shifts: v
        ).value()
    ).value()

Template.teamShiftsTable.bindI18nNamespace('goingnowhere:volunteers')
Template.teamShiftsTable.onCreated () ->
  template = this
  teamId = template.data._id
  template.shifts = new ReactiveVar([])
  template.grouping = new ReactiveVar(new Set())
  template.shiftUpdateDep = new Tracker.Dependency
  template.autorun () ->
    template.shiftUpdateDep.depend()
    share.templateSub(template,"ShiftSignups.byTeam",teamId)
    if template.subscriptionsReady()
      sel = {parentId: teamId}
      currentDate = Template.currentData().date
      if currentDate
        # this is already a moment object
        startOfDay = currentDate.clone().startOf('day')
        endOfDay = currentDate.clone().endOf('day')
        sel =
          $and: [
            sel,
            { start: { $gte: startOfDay.toDate() , $lte: endOfDay.toDate() } },
          ]
      # getShift is in stats.coffee
      template.shifts.set(share.getShifts(sel))

Template.teamShiftsTable.helpers
  ShiftDateInline: () -> ShiftDateInline
  'groupedShifts': () ->
    _.chain(Template.instance().shifts.get())
    .groupBy('groupId')
    .map((v,k) ->
      title: v[0].title
      groupId: k
      shifts: v
    ).value()
  'getRandomShiftId': (groupId) ->
    share.TeamShifts.findOne({groupId})?._id

Template.teamShiftsTable.events commonEvents

Template.teamProjectsTable.bindI18nNamespace('goingnowhere:volunteers')
Template.teamProjectsTable.onCreated () ->
  template = this
  template.teamId = template.data._id
  share.templateSub(template,"ProjectSignups.byTeam",template.teamId)

Template.teamProjectsTable.helpers
  ProjectDateInline: () -> ProjectDateInline
  allProjects: () ->
    share.Projects.find({parentId: Template.instance().teamId}).map((project) ->
      signups = share.ProjectSignups.find(
        {shiftId: project._id, status: 'confirmed'},
        {sort: { start: 1} }
      ).fetch()
      _.extend(project,{volunteers: signups, confirmed: signups.length })
    )

Template.teamProjectsTable.events _.extend(
  commonEvents,
  'click [data-action="edit-enrollment"]': (event,template) ->
    userId = $(event.currentTarget).data('userid')
    shiftId = $(event.currentTarget).data('shiftid')
    type = $(event.currentTarget).data('type')
    signup = share.ProjectSignups.findOne({ userId, shiftId })
    project = share.Projects.findOne(shiftId)
    AutoFormComponents.ModalShowWithTemplate("projectSignupForm",{
      project,
      signup
      }, project.title)
)

Template.projectStaffingChart.bindI18nNamespace('goingnowhere:volunteers')
Template.projectStaffingChart.helpers
  stackedBarData: (project) ->
    confirmedSignups = Template.currentData().confirmedSignups
    signupData = _.extend(projectSignupsConfirmed(project), { _id: project._id })
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
