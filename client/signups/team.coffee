import { Chart } from 'chart.js'
import moment from 'moment-timezone'

import { projectSignupsConfirmed } from '../../both/stats'
import { getShifts } from '../../both/stats'

Template.teamShiftsRota.bindI18nNamespace('goingnowhere:volunteers')
Template.teamShiftsRota.onCreated () ->
  template = this
  teamId = template.data._id
  template.shifts = new ReactiveVar([])
  template.grouping = new ReactiveVar(new Set())
  template.shiftUpdateDep = new Tracker.Dependency
  share.templateSub(template,"Signups.byTeam",teamId,'shift')
  template.autorun () ->
    if template.subscriptionsReady()
      sel = {parentId: teamId}
      template.shifts.set(getShifts(sel))

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
