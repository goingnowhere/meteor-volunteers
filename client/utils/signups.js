import { Meteor } from 'meteor/meteor'
import { Bert } from 'meteor/themeteorchef:bert'
import { t } from '../components/common/i18n'
import { meteorCall } from './methodUtils'

export const bailCall = (
  Volunteers, {
    parentId,
    _id,
    shiftId = _id,
    userId = Meteor.userId(),
    signupId,
    rotaId,
  },
  callback = () => {},
) => () => {
  if (window.confirm(t('shift_cancel_confirm'))) {
    meteorCall(Volunteers, 'signups.bail', signupId ? { _id: signupId, rotaId } : {
      parentId,
      shiftId,
      userId,
      rotaId,
    }, callback)
  }
}

const applyErrorCallback = (err) => {
  if (!err) return
  if (err.error === 409 && err.reason === 'Double Booking') {
    Bert.alert({
      hideDelay: 6500,
      title: t('double_booking'),
      message: t('double_booking_msg'),
      type: 'warning',
      style: 'growl-top-right',
    })
  } else if (err.error === 409) {
    Bert.alert({
      hideDelay: 6500,
      title: t('shift_full'),
      message: t('shift_full_msg'),
      type: 'warning',
      style: 'growl-top-right',
    })
  } else {
    Bert.alert({
      hideDelay: 6500,
      title: t('error'),
      message: err.reason,
      type: 'danger',
      style: 'growl-top-right',
    })
  }
}

export const applyCall = (
  Volunteers,
  callback = () => {},
) => ({
  _id,
  shiftId = _id,
  type,
  parentId,
  userId = Meteor.userId(),
  rotaId,
}) => {
  const signup = {
    parentId,
    shiftId,
    userId,
    type,
    rotaId,
  }
  if (type === 'project') {
    console.error('Project signups not supported')
    applyErrorCallback({ reason: 'Please report this error to fist@goingnowhere.org' })
  } else {
    // FIXME This was actually being called with null. If called with an error will lead to multiple
    // messages. We need to combine this with methodUtils handling.
    // meteorCall(Volunteers, 'signups.insert', signup, applyErrorCallback)
    meteorCall(Volunteers, 'signups.insert', signup, callback)
  }
}
