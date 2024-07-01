import React from 'react'

import { T, t } from '../common/i18n'

const signupMessages = {
  public: 'join',
  requireApproval: 'apply',
}

const numLeft = (gaps, spotsLeft) =>
  `${gaps || spotsLeft} ${t(gaps ? 'people_needed' : 'spots_left')}`

export const SignupShiftButtons = ({
  onClickSignup,
  policy,
  min,
  max,
  signups,
  ...duty
}) => {
  const signedUp = signups?.confirmed || 0
  // TODO this should use the server-calculated versions
  const gaps = Math.max(0, min - signedUp)
  const spotsLeft = Math.max(0, max - signedUp)
  return policy === 'adminOnly'
    ? <T>admin_only</T>
    : (
      <button
        className="btn btn-primary btn-action"
        type="button"
        onClick={() => onClickSignup({ policy, ...duty })}
        disabled={!spotsLeft}
      >
        {`${t(signupMessages[policy])} (${numLeft(gaps, spotsLeft)})`}
      </button>
    )
}
