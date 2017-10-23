import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

leadPolicy = ["public";"adminOnly","requireApproval"]

share.Schemas = {}

CommonTask = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  title:
    type: String
    label: () -> TAPi18n.__("title")
    optional: true
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
        placeholder: "min"
  max:
    type: Number
    label: () -> TAPi18n.__("min_members")
    optional: true
    autoform:
      afFieldInput:
        placeholder: "max"
  policy:
    type: String
    label: () -> TAPi18n.__("policy")
    allowedValues: leadPolicy
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

share.Schemas.TeamShifts = new SimpleSchema(
  start:
    type: Date
    label: () -> TAPi18n.__("start")
    autoform:
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
)

share.Schemas.TeamShifts.extend(CommonTask)

share.Schemas.Lead = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  userId:
    type: String
    label: () -> TAPi18n.__("user")
    optional: true
    autoform:
      type: "select2"
      options: () ->
        Meteor.users.find().map((e) ->
          {value: e._id, label: (share.getUserName(e._id,true))})
  role:
    type: String
    label: () -> TAPi18n.__("role")
    autoform:
      options: () ->
        _.map(share.roles.get(), (e) -> {value: e, label: TAPi18n.__(e)})
      # defaultValue: "lead"
  title:
    type: String
    label: () -> TAPi18n.__("title")
  description:
    type: String
    label: () -> TAPi18n.__("description")
    optional: true
    autoform:
      rows: 5
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
    allowedValues: leadPolicy
    autoform:
      defaultValue: "public"
)
