import SimpleSchema from 'simpl-schema'
import moment from 'moment-timezone'
import { getSkillsList, getQuirksList } from '../utils/unit'
import { t } from '../utils/i18n'

export const dutyTypes = ['lead', 'shift', 'project', 'task']
export const signupStatuses = ['confirmed', 'pending', 'refused', 'bailed', 'cancelled']

// For some reason it doesn't work to just add this at a higher level
SimpleSchema.extendOptions(['autoform'])

// this is the base Volunteers form schema
export const volunteerFormSchema = new SimpleSchema({
  userId: {
    type: String,
    optional: true,
    autoValue() { return this.userId },
    autoform: {
      omit: true,
    },
  },
  createdAt: {
    type: Date,
    optional: true,
    autoValue() {
      if (this.isInsert) return new Date()
      return this.unset()
    },
    autoform: {
      omit: true,
    },
  },
  skills: {
    type: Array,
    label: () => t('skills'),
    optional: false,
    autoform: {
      // XXX bug in autoform https://github.com/aldeed/meteor-autoform/issues/1635
      // group: () -> t('preferences')
      group: 'Preferences',
      groupHelp: () => t('preferences_help'),
      type: 'select2',
      options: getSkillsList,
      afFieldHelpText: () => t('skills_help'),
      afFieldInput: {
        multiple: true,
        select2Options: () => ({ width: '100%' }),
      },
    },
  },
  'skills.$': String,
  quirks: {
    type: Array,
    label: () => t('quirks'),
    optional: false,
    autoform: {
      // group: () -> t('preferences')
      group: 'Preferences',
      type: 'select2',
      options: getQuirksList,
      afFieldHelpText: () => t('quirks_help'),
      afFieldInput: {
        multiple: true,
        select2Options: () => ({ width: '100%' }),
      },
    },
  },
  'quirks.$': String,
  private_notes: {
    type: String,
    label: () => t('private_notes'),
    optional: true,
    max: 1000,
    autoform: {
      rows: 4,
      omit: true,
    },
  },
})

export const SignupSchema = new SimpleSchema({
  parentId: {
    type: String,
    autoform: {
      type: 'hidden',
    },
  },
  shiftId: {
    type: String,
    autoform: {
      type: 'hidden',
    },
  },
  userId: {
    type: String,
    autoform: {
      type: 'hidden',
    },
  },
  type: {
    type: String,
    allowedValues: dutyTypes,
    autoform: {
      type: 'hidden',
    },
  },
  createdAt: {
    type: Date,
    optional: true,
    autoValue() {
      return this.isInsert ? new Date() : undefined
    },
    autoform: {
      omit: true,
    },
  },
  // true if the user was enrolled for this shift by an admin
  enrolled: {
    type: Boolean,
    optional: true,
    defaultValue: false,
    autoform: {
      type: 'hidden',
    },
  },
  status: {
    type: String,
    allowedValues: signupStatuses,
    autoform: {
      type: 'hidden',
      defaultValue: 'pending',
    },
  },
  // true if the user an admin confirmed or refused the shift
  reviewed: {
    type: Boolean,
    optional: true,
    defaultValue: false,
    autoform: {
      omit: true,
    },
  },
  // true if the notification for this shift was already sent
  notification: {
    type: Boolean,
    optional: true,
    defaultValue: false,
    autoform: {
      omit: true,
    },
  },

  // Project signup only fields
  start: {
    type: Date,
    label: () => t('start'),
    optional: true,
    custom() {
      if (this.field('type').value === 'project') {
        if (!this.field('start').value) {
          return 'noProjectDate'
        }
      } else if (this.field('start').value) {
        return 'extraSignupDate'
      }
      return undefined
    },
  },
  end: {
    type: Date,
    label: () => t('end'),
    optional: true,
    custom() {
      if (this.field('type').value === 'project') {
        if (!this.field('end').value) {
          return 'noProjectDate'
        }
        const start = moment(this.field('start').value)
        if (!moment(this.field('end').value).isSameOrAfter(start)) return 'minDateCustom'
      } else if (this.field('end').value) {
        return 'extraSignupDate'
      }
      return undefined
    },
  },
})
