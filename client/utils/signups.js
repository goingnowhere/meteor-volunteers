import { Meteor } from 'meteor/meteor'
import { Bert } from 'meteor/themeteorchef:bert'
import { t } from '../components/common/i18n'
import { meteorCall } from '../../both/utils/methodUtils'

export const bailCall = (Volunteers, {
  parentId,
  _id,
  shiftId = _id,
  userId = Meteor.userId(),
}) => () => {
  // I18N
  if (window.confirm('Are you sure you want to cancel this shift?')) {
    meteorCall(Volunteers, 'signups.bail', {
      parentId,
      shiftId,
      userId,
    })
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

export const applyCall = (Volunteers, {
  _id,
  shiftId = _id,
  type,
  parentId,
  userId = Meteor.userId(),
}) => () => {
  const signup = {
    parentId,
    shiftId,
    userId,
    type,
  }
  if (type === 'project') {
    console.error('Project signups not supported')
    applyErrorCallback({ reason: 'Please report this error to fist@goingnowhere.org' })
  } else {
    meteorCall(Volunteers, 'signups.insert', signup, applyErrorCallback)
  }
}
