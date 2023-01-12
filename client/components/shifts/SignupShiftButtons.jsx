import React, { useContext } from 'react'

import { T, t } from '../common/i18n'
import { applyCall } from '../../utils/signups'
import { reactContext } from '../../clientInit'

const signupMessages = {
  public: 'join',
  requireApproval: 'apply',
}

const numLeft = (gaps, spotsLeft) =>
  `${gaps || spotsLeft} ${t(gaps ? 'people_needed' : 'spots_left')}`

export const SignupShiftButtons = ({
  policy,
  type,
  min,
  max,
  signedUp = 0,
  ...duty
}) => {
  const Volunteers = useContext(reactContext)
  const gaps = Math.max(0, min - signedUp)
  const spotsLeft = Math.max(0, max - signedUp)
  return policy === 'adminOnly'
    ? <T>admin_only</T>
    : (
      <button
        className="btn btn-primary btn-action"
        type="button"
        onClick={applyCall(Volunteers, { type, ...duty })}
        disabled={!spotsLeft}
      >
        {`${t(signupMessages[policy])} (${numLeft(gaps, spotsLeft)})`}
      </button>
    )
}
