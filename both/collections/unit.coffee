import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

unitPolicy = ["public";"private";"restricted"]

share.getTagList = (sel={}) ->
  tags = _.union.apply null, share.Team.find(sel).map((team) -> team.tags)
  _.map tags, (tag) -> {value: tag, label: tag}

CommonUnit = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
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
  # the unit policy should lock the policy of all entities below
  policy:
    type: String
    label: () -> TAPi18n.__("policy")
    allowedValues: unitPolicy
    defaultValue: "public"
)

share.Schemas.Team = CommonUnit
share.Schemas.Department = CommonUnit
share.Schemas.Division = new SimpleSchema(CommonUnit)
# a division (a top level unit) has 'top' as parentId
share.Schemas.Division.extend(
  parentId:
    type: String
    defaultValue: "TopEntity"
    autoform:
      type: "hidden"
)
