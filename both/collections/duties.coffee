import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '1.x' }, 'goingnowhere:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

share.timezone = new ReactiveVar('Europe/Paris')

moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

policyValues = ["public", "adminOnly", "requireApproval"]
taskPriority = [ "essential", "important", "normal"]

SimpleSchema.setDefaultMessages
  messages:
    en:
      "startBeforeEndCustom": "Start Date can't be after End Date"
      "numberOfDaysCustom": "Set for every day"
      "maxMoreThanMin": "Max must be greater than Min"

share.Schemas = {}

share.Schemas.Common = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  title:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","title")
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","name_help_duty")
  description:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","description")
    optional: true
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","description_help_duty")
      rows: 5
  information:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","practical_information")
    optional: true
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","practical_information_help_duty")
      rows: 5
  priority:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","priority")
    allowedValues: taskPriority
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","priority_help_duty")
      defaultValue: "normal"
  policy:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","policy")
    allowedValues: policyValues
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","policy_help_duty")
      defaultValue: "public"
  groupId:
    type: String
    optional: true
    autoform:
      type: "hidden"
  rotaId:
    type: Number
    optional: true
    autoform:
      type: "hidden"
)

share.Schemas.TeamTasks = new SimpleSchema(
  estimatedTime:
    type: String
    allowedValues: ["1-3hs", "3-6hs", "6-12hs","1d","2ds","more"]
    defaultValue: "1-3hs"
  dueDate:
    type: Date
    label: () -> i18n.__("goingnowhere:volunteers","due_date")
    optional: true
    autoValue: () ->
      if this.field('dueDate').isSet
        moment(this.field('dueDate').value,"DD-MM-YYYY HH:mm").toDate()
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("goingnowhere:volunteers","due_date")
        opts: () ->
          step: 60
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'10:00'
          # minDate: '-1970/01/02'
          # maxDate: '+1970/01/02'
  status:
    type: String
    allowedValues: ["done", "archived","pending"]
    optional: true
    autoform:
      omit: true
)
share.Schemas.TeamTasks.extend(share.Schemas.Common)
share.Schemas.TeamTasks.extend(share.SubSchemas.Bounds)

share.Schemas.TeamShifts = new SimpleSchema()
share.Schemas.TeamShifts.extend(share.SubSchemas.DayDatesTimes)
share.Schemas.TeamShifts.extend(share.Schemas.Common)
share.Schemas.TeamShifts.extend(share.SubSchemas.Bounds)
share.Schemas.TeamShifts.extend(share.SubSchemas.AssociatedProject)

share.Schemas.Lead = new SimpleSchema(share.Schemas.Common)
share.Schemas.Lead.extend(
  responsibilities:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","responsibilities")
    optional: true
    autoform:
      rows: 5
  qualificatons:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","qualificatons")
    optional: true
    autoform:
      rows: 5
  notes:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","notes")
    optional: true
    autoform:
      rows: 5
  policy:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","policy")
    allowedValues: policyValues
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","policy_help_duty")
      defaultValue: "requireApproval"
)

share.Schemas.Projects = new SimpleSchema(share.SubSchemas.DayDates)
share.Schemas.Projects.extend(
  staffing:
    type: Array
    minCount: 1
    autoform:
      type: 'projectStaffing'
    custom: () ->
      days = moment(this.field('end').value).diff(moment(this.field('start').value), 'days') + 1
      unless this.value.length == days
        return "numberOfDaysCustom"
  'staffing.$': share.SubSchemas.Bounds
)
share.Schemas.Projects.extend(share.Schemas.Common)
