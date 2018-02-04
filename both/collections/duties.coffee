import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

policyValues = ["public", "adminOnly", "requireApproval"]
taskPriority = [ "essential", "important", "normal"]

share.Schemas = {}

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
    autoform:
      omit: true
)

CommonTask = new SimpleSchema(
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
    # TODO: if max is not set, it should be equal to min
    autoform:
      afFieldInput:
        placeholder: "max"
)
CommonTask.extend(Common)

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
share.Schemas.TeamTasks.extend(CommonTask)

getUniqueShifts = () ->
  allShifts = share.TeamShifts.find({},{sort: {title: 1}}).fetch()
  _.uniq(allShifts, false, (s) -> s.title).map((s) -> {label: s.title, value: s._id})

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
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","end")
        opts: () ->
          step: 15
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'08:00'
          # minDate:
          # maxDate:
  startTime:
    type: Number
    optional: true
    autoValue: () -> moment(this.field('start').value).hour()
    autoform:
      omit: true
  endTime:
    type: Number
    optional: true
    autoValue: () -> moment(this.field('end').value).hour() + 1
    autoform:
      omit: true
)

share.Schemas.TeamShifts.extend(CommonTask)

share.Schemas.Lead = new SimpleSchema(CommonTask)
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
        type: "date"
        placeholder: () -> i18n.__("abate:volunteers","start")
  end:
    type: Date
    label: () -> i18n.__("end")
    custom: () ->
      start = moment(this.field('start').value)
      # console.log('checking', this.value, start.value, moment(this.value), moment(start.value))
      if !moment(this.value).isAfter(start)
        "Fail"# TODO find some way to display message? { type: SimpleSchema.ErrorTypes.MIN_DATE, min: start.format('dd Mo') }
    autoform:
      afFieldInput:
        type: "date"
        placeholder: () -> i18n.__("end")
  # startTime:
  #   type: Date
  #   label: () => i18n.__('daily_start_time')
  #   autoform:
  staffing:
    type: Array
    minCount: 1
    custom: () ->
      days = moment(this.obj.end)
      console.log('custom validator', this)
    # autoform:
    #   type: 'inlineArray'
    #   afFieldInput:
    #     type: 'range'
  'staffing.$':
    type: new SimpleSchema(
      min:
        type: SimpleSchema.Integer
      max:
        type: SimpleSchema.Integer
    )
    autoform:
      afArrayField:
        type: 'inlineArray'
)
share.Schemas.Projects.extend(Common)
