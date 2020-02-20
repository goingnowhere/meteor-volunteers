import SimpleSchema from 'simpl-schema'
import moment from 'moment-timezone'
import { t } from '../utils/i18n'
import { dayDatesTimesSubschema, dayDatesSubSchema, boundsSubschema } from './subSchemas'

SimpleSchema.setDefaultMessages({
  messages: {
    en: {
      startBeforeEndCustom: "Start Date can't be after End Date",
      numberOfDaysCustom: 'Set for every day',
      maxMoreThanMin: 'Max must be greater than Min',
    },
  },
})

const policyValues = ['public', 'adminOnly', 'requireApproval']
const taskPriority = ['essential', 'important', 'normal']

const commonDutySchema = new SimpleSchema({
  parentId: {
    type: String,
    autoform: {
      type: 'hidden',
    },
  },
  title: {
    type: String,
    label: () => t('title'),
    autoform: {
      afFieldHelpText: () => t('name_help_duty'),
    },
  },
  description: {
    type: String,
    label: () => t('description'),
    optional: true,
    autoform: {
      afFieldHelpText: () => t('description_help_duty'),
      rows: 5,
    },
  },
  information: {
    type: String,
    label: () => t('practical_information'),
    optional: true,
    autoform: {
      afFieldHelpText: () => t('practical_information_help_duty'),
      rows: 5,
    },
  },
  priority: {
    type: String,
    label: () => t('priority'),
    allowedValues: taskPriority,
    autoform: {
      afFieldHelpText: () => t('priority_help_duty'),
      defaultValue: 'normal',
    },
  },
  policy: {
    type: String,
    label: () => t('policy'),
    allowedValues: policyValues,
    autoform: {
      afFieldHelpText: () => t('policy_help_duty'),
      defaultValue: 'public',
    },
  },
})

export const taskSchema = new SimpleSchema({
  estimatedTime: {
    type: String,
    allowedValues: ['1-3hs', '3-6hs', '6-12hs', '1d', '2ds', 'more'],
    defaultValue: '1-3hs',
  },
  dueDate: {
    type: Date,
    label: () => t('due_date'),
    optional: true,
    autoValue() {
      if (this.field('dueDate').isSet) {
        return moment(this.field('dueDate').value, 'DD-MM-YYYY HH:mm').toDate()
      }
      return undefined
    },
    autoform: {
      afFieldInput: {
        type: 'datetimepicker',
        placeholder: () => t('due_date'),
        opts: () => ({
          step: 60,
          format: 'DD-MM-YYYY HH:mm',
          defaultTime: '10:00',
        }),
      },
    },
  },
  status: {
    type: String,
    allowedValues: ['done', 'archived', 'pending'],
    optional: true,
    autoform: {
      omit: true,
    },
  },
})
taskSchema.extend(commonDutySchema)
taskSchema.extend(boundsSubschema)

export const shiftSchema = new SimpleSchema()
shiftSchema.extend(dayDatesTimesSubschema)
shiftSchema.extend(commonDutySchema)
shiftSchema.extend(boundsSubschema)
shiftSchema.extend({
  rotaId: {
    type: String,
    autoform: {
      type: 'hidden',
    },
  },
  rotaIndex: {
    type: Number,
    optional: true,
    autoform: {
      type: 'hidden',
    },
  },
})

export const rotaSchema = new SimpleSchema(commonDutySchema)
rotaSchema.extend(dayDatesSubSchema)
rotaSchema.extend({
  shifts: {
    type: Array,
    minCount: 1,
    autoform: {
      afFieldHelpText: () => t('shifts_help_rota'),
    },
  },
  'shifts.$': {
    type: new SimpleSchema(boundsSubschema).extend({
      startTime: {
        type: String,
        autoform: {
          afFieldInput: {
            type: 'timepicker',
            placeholder: () => t('start'),
          },
        },
      },
      endTime: {
        type: String,
        autoform: {
          afFieldInput: {
            type: 'timepicker',
            placeholder: () => t('end'),
          },
        },
      },
      rotaIndex: {
        type: Number,
        optional: true,
        autoform: { type: 'hidden' },
      },
    }),
    optional: true,
  },
})


export const leadSchema = new SimpleSchema(commonDutySchema)
leadSchema.extend({
  responsibilities: {
    type: String,
    label: () => t('responsibilities'),
    optional: true,
    autoform: {
      rows: 5,
    },
  },
  qualificatons: {
    type: String,
    label: () => t('qualificatons'),
    optional: true,
    autoform: {
      rows: 5,
    },
  },
  notes: {
    type: String,
    label: () => t('notes'),
    optional: true,
    autoform: {
      rows: 5,
    },
  },
  policy: {
    type: String,
    label: () => t('policy'),
    allowedValues: ['requireApproval', 'adminOnly'],
    autoform: {
      afFieldHelpText: () => t('policy_help_duty'),
      defaultValue: 'requireApproval',
    },
  },
})

export const projectSchema = new SimpleSchema(dayDatesSubSchema)
projectSchema.extend({
  staffing: {
    type: Array,
    minCount: 1,
    autoform: {
      type: 'projectStaffing',
    },
    custom() {
      const days = moment(this.field('end').value).diff(moment(this.field('start').value), 'days') + 1
      return this.value.length !== days ? 'numberOfDaysCustom' : undefined
    },
  },
  'staffing.$': boundsSubschema,
})
projectSchema.extend(commonDutySchema)
