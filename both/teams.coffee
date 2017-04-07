import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.2.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

share.Schemas = {}

share.Shifts = new Mongo.Collection 'Volunteers.shifts'
share.Schemas.Shifts = new SimpleSchema(
  teamId: String
  shiftId: String
  usersId: [String]
)
share.Shifts.attachSchema(share.Schemas.Shifts)

share.Tasks = new Mongo.Collection 'Volunteers.tasks'
share.Schemas.Tasks = new SimpleSchema(
  teamId: String
  taskId: String
  usersId: [String]
)
share.Tasks.attachSchema(share.Schemas.Tasks)

CommonTask = new SimpleSchema(
  teamId:
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
  # if not set inherit the visibility of the team
  visibility:
    type: String
    label: () -> TAPi18n.__("visibility")
    allowedValues: ["public";"private"]
    # autoValue: () -> ...
)

share.TeamTasks = new Mongo.Collection 'Volunteers.teamTasks'
share.Schemas.TeamTasks = new SimpleSchema(
  estematedTime:
    type: String
    allowedValues: ["1-3hs", "3-6hs", "6-12hs","1d","2ds","more"]
    defaultValue: "1-3hs"
  dueDate:
    type: Date
    label: () -> TAPi18n.__("due_date")
    optional: true
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
)
share.Schemas.TeamTasks.extend(CommonTask)
share.TeamTasks.attachSchema(share.Schemas.TeamTasks)

share.TeamShifts = new Mongo.Collection 'Volunteers.teamShifts'
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
        validation: "none"
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
    autoValue: () -> moment(this.field('start').value).hour()
  endTime:
    type: Number
    autoValue: () -> moment(this.field('end').value).hour() + 1
)

share.Schemas.TeamShifts.extend(CommonTask)
share.TeamShifts.attachSchema(share.Schemas.TeamShifts)

share.Teams = new Mongo.Collection 'Volunteers.teams'
roleOptions = ["lead","co-lead"]

share.getTagList = () ->
  tags = _.union.apply null, share.Teams.find().map((team) -> team.tags)
  _.map tags, (tag) -> {value: tag, label: tag}

share.Schemas.Teams = new SimpleSchema(
  name:
    type: String
    label: () -> TAPi18n.__("teamname")
  leads:
    type: Array
    label: () -> TAPi18n.__("leads")
    optional: true
    autoform:
      template: "inlineArray"
  "leads.$":
    type: Object
    autoform:
      template: "inlineObject"
  "leads.$.userId":
    type: String
    label: () -> TAPi18n.__("user")
    autoform:
      type: "select2"
      options: () ->
        Meteor.users.find().map((e) ->
          {value: e._id, label: e.emails[0].address })
  "leads.$.role":
    type: String
    label: () -> TAPi18n.__("role")
    autoform:
      options: () -> _.map(roleOptions, (e) -> {value: e, label: TAPi18n.__(e)})
      defaultValue: "lead"
  tags:
    type: Array
    label: () -> TAPi18n.__("tags")
    optional: true
    autoform:
      type: "select2"
      options: share.getTagList
      afFieldInput:
        multiple: true
        select2Options: () -> {tags: true}
  "tags.$": String
  description:
    type: String
    label: () -> TAPi18n.__("description")
    optional: true
    autoform:
      rows: 5
  visibility:
    type: String
    label: () -> TAPi18n.__("visibility")
    allowedValues: ["public";"private"]
  parents:
    type: Array
    optional: true #???
    autoform:
      omit: true
  "parents.$": String
)

share.Teams.attachSchema(share.Schemas.Teams)

share.TeamShifts.before.insert (userId, doc) ->
  doc.start = moment(doc.start,"DD-MM-YYYY HH:mm").toDate()
  doc.end = moment(doc.end,"DD-MM-YYYY HH:mm").toDate()
share.TeamShifts.before.update (userId, doc, fieldNames, modifier, options) ->
  doc = modifier["$set"]
  doc.start = moment(doc.start,"DD-MM-YYYY HH:mm").toDate()
  doc.end = moment(doc.end,"DD-MM-YYYY HH:mm").toDate()

share.TeamTasks.before.insert (userId, doc) ->
  doc.dueDate = moment(doc.dueDate,"DD-MM-YYYY HH:mm").toDate()
share.TeamTasks.before.update (userId, doc, fieldNames, modifier, options) ->
  doc = modifier["$set"]
  doc.dueDate = moment(doc.dueDate,"DD-MM-YYYY HH:mm").toDate()
