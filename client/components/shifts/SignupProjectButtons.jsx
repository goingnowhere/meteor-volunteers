import React from 'react'

import { T } from '../common/i18n'

export const SignupProjectButtons = ({
  showSignupModal,
  duty,
}) => {
  return duty.policy === 'adminOnly'
    ? <T>admin_only</T>
    : (
      <button
        className="btn btn-primary btn-action"
        type="button"
        onClick={() => showSignupModal(duty)}
      >
        <T>choose_date</T>
      </button>
    )
}
