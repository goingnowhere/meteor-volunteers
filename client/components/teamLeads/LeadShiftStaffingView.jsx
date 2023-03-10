import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { t } from '../common/i18n'
import { getDisplayNameFromList } from '../common/DisplayName.jsx'

export function LeadShiftStaffingView({
  signup,
  users,
  count,
  showUserInfo,
  unEnrollUser,
}) {
  return (
    <li className="list-group-item p-0">
      <div className="row align-items-center">
        <div className="col-2">
          {count}
          {signup.enrolled && (
            <small title={t('voluntold')}>
              <FontAwesomeIcon icon="people-pulling" />
            </small>
          )}
        </div>
        <div className="col">
          {getDisplayNameFromList(users, signup.userId, () => showUserInfo?.(signup.userId))}
        </div>
        <div className="col-2">
          <button
            type="button"
            className="btn btn-sm btn-circle"
            onClick={() => unEnrollUser(signup._id)}
          >
            <FontAwesomeIcon icon="trash-alt" />
          </button>
        </div>
      </div>
    </li>
  )
}
