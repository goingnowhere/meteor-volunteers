import { Meteor } from 'meteor/meteor'
import { Bert } from 'meteor/themeteorchef:bert'

import { t } from '../../both/utils/i18n'

export const methodCallback = (cb) => (err, res) => {
  if (err) {
    console.error('Error calling method', err)
    Bert.alert({
      title: t('method_error'),
      message: err.reason,
      type: 'danger',
      style: 'growl-top-right',
    })
  } else {
    try {
      cb(err, res)
    } catch (error) {
      console.error('Error running callback for method', error)
      Bert.alert({
        title: t('method_error'),
        message: error.message,
        type: 'danger',
        style: 'growl-top-right',
      })
    }
  }
}

export function meteorCall(VolClass, methodName, ...args) {
  let nonCallbackArgs = args
  const lastArg = args[args.length - 1]
  let callback
  if (lastArg && typeof lastArg === 'function') {
    callback = lastArg
    nonCallbackArgs = args.slice(0, -1)
  }
  // TODO remove when blaze has been eradicated...
  const Volunteers = VolClass || { eventName: 'nowhere2025' }
  Meteor.call(
    `${Volunteers.eventName}.Volunteers.${methodName}`,
    ...nonCallbackArgs,
    methodCallback((err, res) => callback?.(err, res)),
  )
}
