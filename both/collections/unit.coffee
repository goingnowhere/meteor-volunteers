import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

leadPolicy = ["public";"adminOnly","requireApproval"]

share.getTagList = (sel={}) ->
  tags = _.union.apply null, share.Team.find(sel).map((team) -> team.tags)
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
  # policy:
  #   type: String
  #   label: () -> TAPi18n.__("policy")
  #   allowedValues: leadPolicy
  parentId:
    type: String
    optional: true
    # autoform:
    #   omit: true
)

share.Team = new Mongo.Collection 'Volunteers.team'
share.Schemas.Team = CommonUnit
share.Team.attachSchema(share.Schemas.Team)

share.Department = new Mongo.Collection 'Volunteers.department'
share.Schemas.Department = CommonUnit
share.Department.attachSchema(share.Schemas.Department)

share.Division = new Mongo.Collection 'Volunteers.division'
share.Schemas.Division = CommonUnit
share.Division.attachSchema(share.Schemas.Division)
