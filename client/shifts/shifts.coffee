import SimpleSchema from 'simpl-schema'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

import { collections } from '../../both/collections/initCollections'
import { rotaSchema } from '../../both/collections/duties'
import { DutyBody } from '../components/shifts/DutyBody'

moment = extendMoment(Moment)

sameDayHelper = {
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")
}

meteorCall = (name,args...,lastArg) ->
  if typeof lastArg == 'function'
    callback = lastArg
  else
    args.push(lastArg)
  Meteor.call("#{share.eventName}.Volunteers.#{name}", args... , (err,res) ->
    if !callback && err
      Bert.alert({
        title: i18n.__("goingnowhere:volunteers","method_error"),
        message: err.reason,
        type: 'danger',
        style: 'growl-top-right',
      })
    if callback
      callback(err,res)
    )

AutoForm.addHooks ['InsertTeamShiftsFormId','UpdateTeamShiftsFormId'],
  onSuccess: (formType, result) ->
    AutoFormComponents.modalHide()
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})

templateSub = (template,name,args...) ->
  template.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

Template.projectSignupForm.bindI18nNamespace('goingnowhere:volunteers')
Template.projectSignupForm.onCreated () ->
  template = this
  if template.data?.signup
    template.signup = template.data.signup
  project = template.data.project
  templateSub(template,"Signups.byDuty",project._id,"project")
  template.allDays = new ReactiveVar([])
  template.confirmed = new ReactiveVar([])
  meteorCall("getProjectStaffing", project._id,
    (err, confirmed) ->
      unless err
        template.confirmed.set(confirmed)
  )
  template.autorun () ->
    if template.subscriptionsReady()
      start = moment(project.start)
      end = moment(project.end)
      projectLength = end.diff(start, 'days')
      allDays = Array.from(moment.range(start,end).by('days'))
      template.allDays.set(allDays)

Template.projectSignupForm.helpers
  DutyBody: () -> DutyBody
  formSchema: () ->
    if Template.instance().signup?.start
      signup = Template.instance().signup
      firstDay = moment(signup.start)
      lastDay = moment(signup.end)
    else
      allDays = Template.instance().allDays.get()
      if allDays.length > 0
        [firstDay, ..., lastDay] = allDays
    new SimpleSchema({
      start:
        type: Date
        label: () -> i18n.__("goingnowhere:volunteers","start")
        autoform:
          afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","project_start_help")
          group: "Period"
          groupHelp: () -> i18n.__("goingnowhere:volunteers","project_period_help")
          afFieldInput:
            type: "datetimepicker"
            opts: () ->
              # formatDate:'DD-MM-YYYY',
              # minDate: firstDay.format('DD-MM-YYYY')
              # maxDate: lastDay.format('DD-MM-YYYY')
              value: firstDay.format('DD-MM-YYYY')
              format: "DD-MM-YYYY"
              timepicker: false
      end:
        type: Date
        label: () -> i18n.__("goingnowhere:volunteers","end")
        autoform:
          afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","project_end_help")
          group: "Period"
          afFieldInput:
            type: "datetimepicker"
            opts: () ->
              # formatDate:'DD-MM-YYYY',
              # minDate: firstDay.format('DD-MM-YYYY')
              # maxDate: lastDay.format('DD-MM-YYYY')
              value: lastDay.format('DD-MM-YYYY')
              format: "DD-MM-YYYY"
              timepicker: false
      parentId:
        type: String
        autoform:
          type: "hidden"
      shiftId:
        type: String
        autoform:
          type: "hidden"
      userId:
        type: String
        autoform:
          type: "hidden"
      type:
        type: String
        autoform:
          type: "hidden"
        defaultValue: 'project'
      })

  methodNameInsert: () -> "#{collections.signups._name}.insert"
  methodNameUpdate: () -> "#{collections.signups._name}.update"

  updateLabel: () ->
    if Template.currentData().project.policy == "public"
      i18n.__("goingnowhere:volunteers",".join")
    else
      i18n.__("goingnowhere:volunteers",".apply")

  confirmed: () -> Template.instance().confirmed.get()

AutoForm.addHooks([
  'projectSignupsInsert',
  'projectSignupsUpdate',
  'InsertShiftGroupFormId',
  'UpdateShiftGroupFormId'
],
  onSuccess: () ->
    AutoFormComponents.modalHide()
)
