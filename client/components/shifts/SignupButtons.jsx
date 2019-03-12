import React from 'react'

import { T, t } from '../common/i18n'
import { applyCall } from '../../utils/signups'

const signupMessages = {
  public: 'join',
  requireApproval: 'apply',
}

const numLeft = (gaps, spotsLeft) =>
  `${gaps || spotsLeft} ${t(gaps ? 'people_needed' : 'spots_left')}`

export const SignupButtons = ({
  policy,
  type,
  min,
  max,
  signedUp = 0,
  ...duty
}) => {
  const gaps = Math.max(0, min - signedUp)
  const spotsLeft = type === 'project' ? 1 : Math.max(0, max - signedUp)
  return policy === 'adminOnly'
    ? <T>admin_only</T>
    : (
      <button
        className="btn btn-primary btn-action"
        type="button"
        onClick={applyCall({ type, ...duty })}
        disabled={!spotsLeft}
      >
        {type === 'project'
          ? t('choose_date')
          : `${t(signupMessages[policy])} (${numLeft(gaps, spotsLeft)})`}
      </button>
    )
}

