import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.2.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

share.Schemas = {}

share.getTagList = () ->
  tags = _.union.apply null, share.Team.find().map((team) -> team.tags)
  _.map tags, (tag) -> {value: tag, label: tag}

CommonUnit = new SimpleSchema(
  name:
    type: String
    label: () -> TAPi18n.__("name")
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
  parentId:
    type: String
    optional: true
    autoform:
      omit: true
)

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
  visibility:
    type: String
    label: () -> TAPi18n.__("visibility")
    allowedValues: ["public";"private"]
)

share.TeamTasks = new Mongo.Collection 'Volunteers.teamTasks'
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
)
share.Schemas.TeamTasks.extend(CommonTask)
share.TeamTasks.attachSchema(share.Schemas.TeamTasks)

share.TeamShifts = new Mongo.Collection 'Volunteers.teamShifts'
share.Schemas.TeamShifts = new SimpleSchema(
  start:
    type: Date
    label: () -> TAPi18n.__("start")
    autoValue: () ->
      moment(this.field('start').value,"DD-MM-YYYY HH:mm").toDate()
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
    autoValue: () ->
      moment(this.field('end').value,"DD-MM-YYYY HH:mm").toDate()
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
    autoform:
      omit: true
  endTime:
    type: Number
    autoValue: () -> moment(this.field('end').value).hour() + 1
    autoform:
      omit: true
)

share.Schemas.TeamShifts.extend(CommonTask)
share.TeamShifts.attachSchema(share.Schemas.TeamShifts)

share.Lead = new Mongo.Collection 'Volunteers.lead'

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
  position:
    type: String
    allowedValues: ["team","department","division"]
    autoform:
      type: "hidden"
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
    autoform:
      defaultValue: "public"
)
share.Lead.attachSchema(share.Schemas.Lead)

share.Team = new Mongo.Collection 'Volunteers.team'
share.Schemas.Team = CommonUnit
share.Team.attachSchema(share.Schemas.Team)

share.Department = new Mongo.Collection 'Volunteers.department'
share.Schemas.Department = CommonUnit
share.Department.attachSchema(share.Schemas.Department)

share.Division = new Mongo.Collection 'Volunteers.division'
share.Schemas.Division = CommonUnit
share.Division.attachSchema(share.Schemas.Division)
