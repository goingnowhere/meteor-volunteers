import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
checkNpmVersions { 'simpl-schema': '0.3.x' }, 'abate:volunteers'
import SimpleSchema from 'simpl-schema'
SimpleSchema.extendOptions(['autoform'])

import Moment from 'moment'
import 'moment-timezone'
import { extendMoment } from 'moment-range'

share.timezone = new ReactiveVar('Europe/Paris')

moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

share.SubSchemas = {}

share.SubSchemas.Bounds = new SimpleSchema(
  min:
    type: Number
    label: () -> i18n.__("abate:volunteers","min_people")
    optional: true
    autoform:
      defaultValue: 4
      afFieldInput:
        min: 1
        placeholder: "min"
  max:
    type: Number
    label: () -> i18n.__("abate:volunteers","max_people")
    optional: true
    custom: () ->
      unless this.value >= this.siblingField('min').value
        return "maxMoreThanMin"
    autoform:
      defaultValue: 5
      afFieldInput:
        min: 1
        placeholder: "max"
)

share.SubSchemas.DayDates = new SimpleSchema(
  start:
    type: Date
    label: () -> i18n.__("abate:volunteers","start")
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","start")
        opts: () ->
          format: 'DD-MM-YYYY'
          timepicker: false
          # altFormat: 'd-m-Y'
  end:
    type: Date
    label: () -> i18n.__("abate:volunteers","end")
    custom: () ->
      start = moment(this.field('start').value)
      unless moment(this.value).isAfter(start)
        return "startBeforeEndCustom"
    autoform:
      defaultValue: () ->
        AutoForm.getFieldValue('start')
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","end")
        opts: () ->
          format: 'DD-MM-YYYY'
          timepicker: false
          # altFormat: 'd-m-Y'
)

# This is basically the same as above but with time.
# maybe is possible to further refactor to avoid code duplication
share.SubSchemas.DayDatesTimes = new SimpleSchema(
  start:
    type: Date
    label: () -> i18n.__("abate:volunteers","start")
    autoform:
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","start")
        opts: () ->
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'05:00'
  end:
    type: Date
    label: () -> i18n.__("abate:volunteers","end")
    custom: () ->
      start = moment(this.field('start').value)
      unless moment(this.value).isAfter(start)
        return "startBeforeEndCustom"
    autoform:
      defaultValue: () ->
        AutoForm.getFieldValue('start')
      afFieldInput:
        type: "datetimepicker"
        placeholder: () -> i18n.__("abate:volunteers","end")
        opts: () ->
          format: 'DD-MM-YYYY HH:mm'
          defaultTime:'08:00'
)