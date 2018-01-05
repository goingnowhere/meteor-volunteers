import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

policyValues = ["public", "adminOnly", "requireApproval"]
taskPriority = [ "essential", "important", "normal"]

share.Schemas = {}

CommonTask = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  title:
    type: String
    label: () -> TAPi18n.__("title")
  description:
    type: String
    label: () -> TAPi18n.__("description")
    optional: true
    autoform:
      rows: 5
  min:
    type: Number
    label: () -> TAPi18n.__("min_members")
    optional: true
    autoform:
      afFieldInput:
        min: 1
        placeholder: "min"
  max:
    type: Number
    label: () -> TAPi18n.__("max_members")
    optional: true
    # TODO: if max is not set, it should be equal to min
    autoform:
      afFieldInput:
        placeholder: "max"
  priority:
    type: String
    label: () -> TAPi18n.__("priority")
    allowedValues: taskPriority
    autoform:
      defaultValue: "normal"
  policy:
    type: String
    label: () -> TAPi18n.__("policy")
    allowedValues: policyValues
    autoform:
      defaultValue: "public"
)

share.Schemas.TeamTasks = new SimpleSchema(
  estimatedTime:
    type: String
    allowedValues: ["1-3hs", "3-6hs", "6-12hs","1d","2ds","more"]
    defaultValue: "1-3hs"
  dueDate:
    type: Date
    label: () -> TAPi18n.__("due_date")
    optional: true
    autoValue: () ->
      if this.field('dueDate').isSet
        moment(this.field('dueDate').value,"DD-MM-YYYY HH:mm").toDate()
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> TAPi18n.__("due_date")
        opts: () ->
          step: 60
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'10:00'
          # minDate: '-1970/01/02'
          # maxDate: '+1970/01/02'
  status:
    type: String
    allowedValues: ["done", "archived","pending"]
)
share.Schemas.TeamTasks.extend(CommonTask)

getUniqueShifts = () ->
  allShifts = share.TeamShifts.find({},{sort: {title: 1}}).fetch()
  _.uniq(allShifts, false, (s) -> s.title).map((s) -> {label: s.title, value: s._id})

share.Schemas.TeamShifts = new SimpleSchema(
  start:
    type: Date
    label: () -> TAPi18n.__("start")
    autoform:
      # defaultValue: () ->
      #   AutoForm.getFieldValue('start')
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> TAPi18n.__("start")
        opts: () ->
          step: 15
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'05:00'
          # minDate:
          # maxDate:
  end:
    type: Date
    label: () -> TAPi18n.__("end")
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> TAPi18n.__("end")
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
  # group:
  #   type: Array
  #   label: () -> TAPi18n.__("group")
  #   optional: true
  #   autoform:
  #     type: "select2"
  #     options: () -> getUniqueShifts(AutoForm.getFieldValue('parentId'))
  #     afFieldInput:
  #       multiple: true
  #       select2Options: () -> {multiple: true}
  # "group.$": String
)

share.Schemas.TeamShifts.extend(CommonTask)

share.Schemas.Lead = new SimpleSchema(CommonTask)
share.Schemas.Lead.extend(
  responsibilities:
    type: String
    label: () -> TAPi18n.__("responsibilities")
    optional: true
    autoform:
      rows: 5
  qualificatons:
    type: String
    label: () -> TAPi18n.__("qualificatons")
    optional: true
    autoform:
      rows: 5
  notes:
    type: String
    label: () -> TAPi18n.__("notes")
    optional: true
    autoform:
      rows: 5
  policy:
    type: String
    label: () -> TAPi18n.__("policy")
    allowedValues: policyValues
    autoform:
      defaultValue: "requireApproval"
)
