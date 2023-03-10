import React, { useContext } from 'react'

import { AutoFormComponents } from 'meteor/abate:autoform-components'
import { AutoForm } from 'meteor/aldeed:autoform'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { meteorCall } from '../../utils/methodUtils'
import { reactContext } from '../../clientInit'
import { T, t } from '../common/i18n'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { LeadShiftStaffingView } from './LeadShiftStaffingView.jsx'

export function LeadShiftView({
  shift,
  users,
  reload,
  showUserInfo,
}) {
  const Volunteers = useContext(reactContext)
  const { collections } = Volunteers

  const editShift = () =>
    AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate',
      { form: { collection: collections.dutiesCollections.shift }, data: shift }, '', 'lg')
  const deleteShift = (shiftId) => {
    if (window.confirm('Are you sure you want to delete this shift?')) {
      meteorCall(Volunteers, 'teamShifts.remove', shiftId)
      reload()
    }
  }
  const enrollUser = () =>
    // TODO Also need to reload shifts and can probably move from autoform modal
    AutoFormComponents.ModalShowWithTemplate('shiftEnrollUsersTable', {
      data: {
        teamId: shift.parentId,
        shiftId: shift._id,
        duty: 'shift',
        policy: shift.policy,
      },
    })

  AutoForm.addHooks([
    'InsertRotasFormId',
    'UpdateRotasFormId',
    'UpdateTeamShiftsFormId',
  ], {
    onSuccess() {
      reload()
      AutoFormComponents.modalHide()
    },
  })

  const unEnrollUser = (signupId) => {
    meteorCall(Volunteers, 'signups.remove', signupId)
    reload()
  }
  // TODO get rid of the tables...
  return (
    <>
      <tr>
        <th scope="row">
          <span>
            {shift.priority === 'essential' && (
              <span className="text-danger" title={t('essential')}><FontAwesomeIcon icon="exclamation-circle" /></span>
            )}
            {shift.policy === 'private' && <FontAwesomeIcon icon="user-secret" title={t('private')} />}
            {shift.policy === 'requireApproval' && <FontAwesomeIcon icon="lock" title={t('require_approval')} />}
            {shift.policy === 'adminOnly' && <FontAwesomeIcon icon="user-secret" title={t('admin_only')} />}
          </span>
        </th>
        <td><ShiftDateInline start={shift.start} end={shift.end} /></td>
        <td colSpan="2">
          {/* <!-- {{> progressBarShifts shift}} --> */}
          <div title={`Min: ${shift.min} - Max: ${shift.max} - Confirmed: ${shift.confirmed}`}>
            {shift.needed !== 0 ? (
              <span className="inline">{shift.needed} <T>more_needed</T></span>
            ) : (
            // <!-- <span className="bg-success"> -->
              <T>full</T>
            // <!-- </span> -->
            )}
          </div>
        </td>
        <td>
          <div className="btn-group inline pull-left">
            <button
              type="button"
              className="btn btn-sm btn-circle"
              onClick={() => editShift(shift)}
            >
              <FontAwesomeIcon icon="pen-to-square" />
            </button>
            <button
              type="button"
              className="btn btn-sm btn-circle"
              onClick={() => deleteShift(shift._id)}
            >
              <FontAwesomeIcon icon="trash-alt" />
            </button>
            <button
              type="button"
              className="btn btn-sm btn-circle"
              onClick={() => enrollUser()}
            >
              <FontAwesomeIcon icon="user-plus" />
            </button>
          </div>
        </td>
      </tr>
      {shift.confirmed > 0 && (
        <tr>
          <td colSpan="4" className="p-1">
            <ul className="list-group list-group-flush">
              {shift.signups.map((signup, index) => (
                <LeadShiftStaffingView
                  key={signup._id}
                  count={index + 1}
                  signup={signup}
                  users={users}
                  showUserInfo={showUserInfo}
                  unEnrollUser={unEnrollUser}
                />
              ))}
            </ul>
          </td>
        </tr>
      )}
    </>
  )
}
