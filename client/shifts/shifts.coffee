import SimpleSchema from 'simpl-schema'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

import { collections } from '../../both/collections/initCollections'
import { rotaSchema } from '../../both/collections/duties'
import { DutyBody } from '../components/shifts/DutyBody';

moment = extendMoment(Moment)

sameDayHelper = {
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")
}

Template.shiftDateInline.helpers sameDayHelper

Template.addShift.bindI18nNamespace('goingnowhere:volunteers')
Template.addShift.helpers
  'form': () -> {
    collection: collections.shift,
    update: {label: i18n.__("goingnowhere:volunteers","update_shift") },
    insert: {label: i18n.__("goingnowhere:volunteers","new_shift") }
  }
  'data': () -> parentId: Template.currentData().team?._id

Template.addTask.bindI18nNamespace('goingnowhere:volunteers')
Template.addTask.helpers
  'form': () -> { collection: collections.task }
  'data': () ->
    parentId: Template.currentData().team?._id

AutoForm.addHooks ['InsertTeamShiftsFormId','UpdateTeamShiftsFormId'],
  onSuccess: (formType, result) ->
    AutoFormComponents.modalHide()
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})

Template.projectStaffingInput.bindI18nNamespace('goingnowhere:volunteers')
Template.projectStaffingInput.helpers
  day: (index) ->
    start = AutoForm.getFieldValue('start')
    return moment(start).add(index, 'days').format('MMM Do')
  datesSet: () ->
    start = AutoForm.getFieldValue('start')
    end = AutoForm.getFieldValue('end')
    return start? && end? && moment(start).isBefore(end)
  staffingArray: () ->
    start = AutoForm.getFieldValue('start')
    end = AutoForm.getFieldValue('end')
    if start? && end?
      staffing = AutoForm.getFieldValue('staffing') || []
      days = moment(end).diff(moment(start), 'days') + 1
      if days > staffing.length
        return staffing.concat(Array(days - staffing.length).fill({}))
      else
        return staffing.slice(0, days)
AutoForm.addInputType("projectStaffing",
  template: 'projectStaffingInput'
  valueOut: () ->
    values = this.find('[data-index]')
      .map((_, col) ->
        min: $(col).find('[data-field="min"]').val()
        max: $(col).find('[data-field="max"]').val()
      ).get()
    return values
)

Template.projectSignupForm.bindI18nNamespace('goingnowhere:volunteers')
Template.projectSignupForm.onCreated () ->
  template = this
  if template.data?.signup
    template.signup = template.data.signup
  project = template.data.project
  share.templateSub(template,"Signups.byDuty",project._id,"project")
  template.allDays = new ReactiveVar([])
  template.confirmed = new ReactiveVar([])
  share.meteorCall("getProjectStaffing", project._id,
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
