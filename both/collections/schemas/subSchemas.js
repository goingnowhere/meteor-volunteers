import SimpleSchema from 'simpl-schema'
import moment from 'moment-timezone'
import { AutoForm } from 'meteor/aldeed:autoform'
import { t } from '../../utils/i18n'

export const boundsSubschema = new SimpleSchema({
  min: {
    type: Number,
    label: () => t('min_people'),
    optional: true,
    autoform: {
      defaultValue: 4,
      afFieldInput: {
        min: 1,
        placeholder: 'min',
      },
    },
  },
  max: {
    type: Number,
    label: () => t('max_people'),
    optional: true,
    custom() {
      return this.value < this.siblingField('min').value ? 'maxMoreThanMin' : undefined
    },
    autoform: {
      defaultValue: 5,
      afFieldInput: {
        min: 1,
        placeholder: 'max',
      },
    },
  },
})

export const dayDatesSubSchema = new SimpleSchema({
  start: {
    type: Date,
    label: () => t('start'),
    autoform: {
      afFieldInput: {
        type: 'datetimepicker',
        placeholder: () => t('start'),
        opts: () => ({
          format: 'DD-MM-YYYY',
          timepicker: false,
        }),
      },
    },
  },
  end: {
    type: Date,
    label: () => t('end'),
    custom() {
      const start = moment(this.field('start').value)
      return !moment(this.value).isSameOrAfter(start) ? 'startBeforeEndCustom' : undefined
    },
    autoform: {
      defaultValue() {
        return AutoForm.getFieldValue('start')
      },
      afFieldInput: {
        type: 'datetimepicker',
        placeholder: () => t('end'),
        opts: () => ({
          format: 'DD-MM-YYYY',
          timepicker: false,
        }),
      },
    },
  },
})

// This is basically the same as above but with time.
// maybe is possible to further refactor to avoid code duplication
export const dayDatesTimesSubschema = new SimpleSchema({
  start: {
    type: Date,
    label: () => t('start'),
    autoform: {
      afFieldInput: {
        type: 'datetimepicker',
        placeholder: () => t('start'),
        opts: () => ({
          format: 'DD-MM-YYYY HH:mm',
          defaultTime: '05:00',
        }),
      },
    },
  },
  end: {
    type: Date,
    label: () => t('end'),
    custom() {
      const start = moment(this.field('start').value)
      return !moment(this.value).isAfter(start) ? 'startBeforeEndCustom' : undefined
    },
    autoform: {
      defaultValue() {
        return AutoForm.getFieldValue('start')
      },
      afFieldInput: {
        type: 'datetimepicker',
        placeholder: () => t('end'),
        opts: () => ({
          format: 'DD-MM-YYYY HH:mm',
          defaultTime: '08:00',
        }),
      },
    },
  },
})
