import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '1.x' }, 'goingnowhere:volunteers'
import SimpleSchema from 'simpl-schema'
import { getSkillsList, getQuirksList, getLocationList } from './unit'
SimpleSchema.extendOptions(['autoform'])

unitPolicy = ["public";"private"]

share.getTeamProjects = (sel={}) ->
  console.log "AAA"
  share.getProjects(sel).map((project) ->
    team = share.Team.findOne(project.parentId)
    console.log "#{team.name} > #{project.title}"
    return {value: project._id, label: "#{team.name} > #{project.title}"}
  )

CommonUnit = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  name:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","name")
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","name_help_team")
  skills:
    type: Array
    label: () -> i18n.__("goingnowhere:volunteers","skills")
    optional: true
    autoform:
      type: "select2"
      options: getSkillsList
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","skills_help_team")
      afFieldInput:
        multiple: true
        select2Options: () -> {
          tags: true,
          width: "100%",
        }
  "skills.$": String
  quirks:
    type: Array
    label: () -> i18n.__("goingnowhere:volunteers","quirks")
    optional: true
    autoform:
      type: "select2"
      options: getQuirksList
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","quirks_help_team")
      afFieldInput:
        multiple: true
        select2Options: () -> {
          tags: true,
          width: "100%",
        }
  "quirks.$": String
  description:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","description")
    optional: true
    autoform:
      rows: 5
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","description_help_team")
  # TODO: the unit policy should lock the policy of all entities below
  email:
    type: String
    optional: true
    autoform:
      label: () -> i18n.__("goingnowhere:volunteers","public_email")
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","public_email_help")
  policy:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","policy")
    allowedValues: unitPolicy
    defaultValue: "public"
    autoform:
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","policy_help_team")
)

share.Schemas.Team = new SimpleSchema(CommonUnit)
share.Schemas.Team.extend(
  location:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","location")
    optional: true
    autoform:
      type: "select2"
      options: getLocationList
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","location_help_team")
      afFieldInput:
        select2Options: () -> {
          tags: true,
          width: "100%",
          placeholder: i18n.__("goingnowhere:volunteers","select_location"),
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
