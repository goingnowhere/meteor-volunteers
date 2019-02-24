import SimpleSchema from 'simpl-schema'
import moment from 'moment-timezone'
import { getSkillsList, getQuirksList } from './unit'
import { signupStatuses } from './volunteer'

# this is the base Volunteers form schema
share.Schemas.VolunteerForm = new SimpleSchema(
  userId:
    type: String
    optional: true
    autoValue: () -> this.userId
    autoform:
      omit: true
  createdAt:
    type: Date
    optional: true
    autoValue: () ->
      if this.isInsert then return new Date
      else this.unset()
    autoform:
      omit: true
  skills:
    type: Array
    label: () -> i18n.__("goingnowhere:volunteers","skills")
    optional: false
    autoform:
      # XXX bug in autoform https://github.com/aldeed/meteor-autoform/issues/1635
      # group: () -> i18n.__("goingnowhere:volunteers","preferences")
      group: "Preferences"
      groupHelp: () -> i18n.__("goingnowhere:volunteers","preferences_help")
      type: "select2"
      options: getSkillsList
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","skills_help")
      afFieldInput:
        multiple: true
        select2Options: () -> {width: '100%'}
  "skills.$": String
  quirks:
    type: Array
    label: () -> i18n.__("goingnowhere:volunteers","quirks")
    optional: false
    autoform:
      # group: () -> i18n.__("goingnowhere:volunteers","preferences")
      group: "Preferences"
      type: "select2"
      options: getQuirksList
      afFieldHelpText: () -> i18n.__("goingnowhere:volunteers","quirks_help")
      afFieldInput:
        multiple: true
        select2Options: () -> {width: '100%'}
  "quirks.$": String
  private_notes:
    type: String
    label: () -> i18n.__("goingnowhere:volunteers","private_notes")
    optional: true
    max: 1000
    autoform:
      rows:4
      omit: true
)

commonSignups = new SimpleSchema(
  parentId:
    type: String
    autoform:
      type: "hidden"
  shiftId:
    type: String
    autoform:
      type: "hidden"
  userId:
    type: String
    autoform:
      type: "hidden"
  createdAt:
    type: Date
    optional: true
    autoValue: () ->
      if this.isInsert then return new Date
    autoform:
      omit: true
  # true if the user was enrolled for this shift by an admin
  enrolled:
    type: Boolean
    optional: true
    defaultValue: false
    autoform:
      type: "hidden"
  status:
    type: String
    allowedValues: signupStatuses
    autoform:
      type: "hidden"
      defaultValue: "pending"
  # true if the user an admin confirmed or refused the shift
  reviewed:
    type: Boolean
    optional: true
    defaultValue: false
    autoform:
      omit: true
  # true if the notification for this shift was already sent
  notification:
    type: Boolean
    optional: true
    defaultValue: false
    autoform:
      omit: true
)
share.Schemas.ShiftSignups = commonSignups
share.Schemas.TaskSignups = commonSignups
share.Schemas.LeadSignups = commonSignups
share.Schemas.ProjectSignups = new SimpleSchema(
  start:
    type: Date
    label: () -> i18n.__("goingnowhere:volunteers", "start")
  end:
    type: Date
    label: () -> i18n.__("goingnowhere:volunteers", "end")
    custom: () ->
      if this.isSet
        start = moment(this.field('start').value)
        if !moment(this.value).isSameOrAfter(start)
          return "minDateCustom"
)
share.Schemas.ProjectSignups.extend(commonSignups)
