import { Meteor } from 'meteor/meteor'
import { Bert } from 'meteor/themeteorchef:bert'

import { t } from '../../both/utils/i18n'

export function meteorCall(VolClass, methodName, ...args) {
  let nonCallbackArgs = args
  const lastArg = args[args.length - 1]
  let callback
  if (lastArg && typeof lastArg === 'function') {
    callback = lastArg
    nonCallbackArgs = args.slice(0, -1)
  }
  // TODO remove when blaze has been eradicated...
  const Volunteers = VolClass || { eventName: 'nowhere2022' }
  Meteor.call(
    `${Volunteers.eventName}.Volunteers.${methodName}`,
    ...nonCallbackArgs,
    (err, res) => {
      if (!callback && err) {
        Bert.alert({
          title: t('method_error'),
          message: err.reason,
          type: 'danger',
          style: 'growl-top-right',
        })
      } else if (callback) {
        callback(err, res)
      }
    },
  )
}
