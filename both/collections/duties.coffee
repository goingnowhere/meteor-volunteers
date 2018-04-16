import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

policyValues = ["public", "adminOnly", "requireApproval"]
taskPriority = [ "essential", "important", "normal"]

SimpleSchema.setDefaultMessages
  messages:
    en:
      "startBeforeEndCustom": "Start Date can't be after End Date"
      "numberOfDaysCustom": "Set for every day"

share.Schemas = {}

Bounds = new SimpleSchema(
  min:
    type: Number
    label: () -> i18n.__("abate:volunteers","min_people")
    optional: true
    autoform:
      afFieldInput:
        min: 1
        placeholder: "min"
  max:
    type: Number
    label: () -> i18n.__("abate:volunteers","max_people")
    optional: true
    autoform:
      defaultValue: () ->
        AutoForm.getFieldValue('min')
      afFieldInput:
        placeholder: "max"
)

Common = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  title:
    type: String
    label: () -> i18n.__("abate:volunteers","title")
  description:
    type: String
    label: () -> i18n.__("abate:volunteers","description")
    optional: true
    autoform:
      rows: 5
  priority:
    type: String
    label: () -> i18n.__("abate:volunteers","priority")
    allowedValues: taskPriority
    autoform:
      defaultValue: "normal"
  policy:
    type: String
    label: () -> i18n.__("abate:volunteers","policy")
    allowedValues: policyValues
    autoform:
      defaultValue: "public"
  groupId:
    type: String
    optional: true
    autoValue: () ->
      if not this.field('groupId').isSet
        Random.id()
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
    label: () -> i18n.__("abate:volunteers","due_date")
    optional: true
    autoValue: () ->
      if this.field('dueDate').isSet
        moment(this.field('dueDate').value,"DD-MM-YYYY HH:mm").toDate()
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","due_date")
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
share.Schemas.TeamTasks.extend(Common)
share.Schemas.TeamTasks.extend(Bounds)

share.Schemas.TeamShifts = new SimpleSchema(
  start:
    type: Date
    label: () -> i18n.__("abate:volunteers","start")
    autoform:
      # defaultValue: () ->
      #   AutoForm.getFieldValue('start')
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","start")
        opts: () ->
          step: 15
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'05:00'
          # minDate:
          # maxDate:
  end:
    type: Date
    label: () -> i18n.__("abate:volunteers","end")
    custom: () ->
      start = moment(this.field('start').value)
      unless moment(this.value).isAfter(start)
        return "startBeforeEndCustom"
    autoform:
      defaultValue: () ->
        AutoForm.getFieldValue('start')
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","end")
        opts: () ->
          step: 15
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'08:00'
          # minDate:
          # maxDate:
)

share.Schemas.TeamShifts.extend(Common)
share.Schemas.TeamShifts.extend(Bounds)

share.Schemas.Lead = new SimpleSchema(Common)
share.Schemas.Lead.extend(
  responsibilities:
    type: String
    label: () -> i18n.__("abate:volunteers","responsibilities")
    optional: true
    autoform:
      rows: 5
  qualificatons:
    type: String
    label: () -> i18n.__("abate:volunteers","qualificatons")
    optional: true
    autoform:
      rows: 5
  notes:
    type: String
    label: () -> i18n.__("abate:volunteers","notes")
    optional: true
    autoform:
      rows: 5
  policy:
    type: String
    label: () -> i18n.__("abate:volunteers","policy")
    allowedValues: policyValues
    autoform:
      defaultValue: "requireApproval"
)

share.Schemas.Projects = new SimpleSchema(
  start:
    type: Date
    label: () -> i18n.__("abate:volunteers","start")
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","start")
        opts: () ->
          format: 'DD-MM-YYYY'
          timepicker: false
  end:
    type: Date
    label: () -> i18n.__("abate:volunteers","end")
    custom: () ->
      start = moment(this.field('start').value)
      unless moment(this.value).isAfter(start)
        return "startBeforeEndCustom"
    autoform:
      defaultValue: () ->
        AutoForm.getFieldValue('start')
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","end")
        opts: () ->
          format: 'DD-MM-YYYY'
          timepicker: false
  staffing:
    type: Array
    minCount: 1
    autoform:
      type: 'projectStaffing'
    custom: () ->
      days = moment(this.field('end').value).diff(moment(this.field('start').value), 'days') + 1
      unless this.value.length == days
        return "numberOfDaysCustom"
  'staffing.$': Bounds
)
share.Schemas.Projects.extend(Common)
