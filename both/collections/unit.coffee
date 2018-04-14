import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

unitPolicy = ["public";"private";"restricted"]

share.getSkillsList = (sel={}) ->
  tags = _.union.apply null, share.Team.find(sel).map((team) -> team.skills)
  _.map tags, (tag) -> {value: tag, label: tag}

share.getQuirksList = (sel={}) ->
  tags = _.union.apply null, share.Team.find(sel).map((team) -> team.quirks)
  _.map tags, (tag) -> {value: tag, label: tag}

share.getLocationList = (sel={}) ->
  locations = _.union.apply null, share.Team.find(sel).map((team) -> team.location)
  _.map locations, (loc) -> {value: loc, label: loc}

CommonUnit = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  name:
    type: String
    label: () -> i18n.__("abate:volunteers","name")
  skills:
    type: Array
    label: () -> i18n.__("abate:volunteers","skills")
    optional: true
    autoform:
      type: "select2"
      options: share.getSkillsList
      afFieldInput:
        multiple: true
        select2Options: () -> {
          tags: true,
          width: "100%",
        }
  "skills.$": String
  quirks:
    type: Array
    label: () -> i18n.__("abate:volunteers","quirks")
    optional: true
    autoform:
      type: "select2"
      options: share.getQuirksList
      afFieldInput:
        multiple: true
        select2Options: () -> {
          tags: true,
          width: "100%",
        }
  "quirks.$": String
  description:
    type: String
    label: () -> i18n.__("abate:volunteers","description")
    optional: true
    autoform:
      rows: 5
  # TODO: the unit policy should lock the policy of all entities below
  policy:
    type: String
    label: () -> i18n.__("abate:volunteers","policy")
    allowedValues: unitPolicy
    defaultValue: "public"
)

share.Schemas.Team = new SimpleSchema(CommonUnit)
share.Schemas.Team.extend(
  location:
    type: String
    label: () -> i18n.__("abate:volunteers","location")
    optional: true
    autoform:
      type: "select2"
      options: share.getLocationList
      afFieldInput:
        select2Options: () -> {
          tags: true,
          width: "100%",
          placeholder: i18n.__("abate:volunteers","select_location"),
          allowClear: true
        }
)

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
