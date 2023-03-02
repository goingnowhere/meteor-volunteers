import { _ } from 'meteor/underscore'
import React, {
  Fragment,
  useState,
  useMemo,
  useContext,
} from 'react'
import { AutoFormComponents } from 'meteor/abate:autoform-components'
import { AutoForm } from 'meteor/aldeed:autoform'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { T, t } from '../common/i18n'
import { Modal } from '../common/Modal.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { reactContext } from '../../clientInit'
import { meteorCall } from '../../utils/methodUtils'
import { useMethodCallData } from '../../utils/useMethodCallData'

const getUsername = (users, userId) => {
  const user = users.find((usr) => usr._id === userId)
  return user && (user.profile.nickname || user.profile.firstName)
}

// used to display all shifts for a given team
export const TeamShiftsTable = ({ date, teamId, UserInfoComponent }) => {
  const Volunteers = useContext(reactContext)
  const { collections } = Volunteers

  const [{ users, duties }, isLoaded, reloadShifts] = useMethodCallData(
    `${Volunteers.eventName}.Volunteers.getTeamDutyStats`,
    { type: 'shift', teamId, date: date && date.toDate() },
  )
  const shiftGroups = useMemo(() => duties && _.groupBy(duties, 'rotaId'), [duties])

  const editShift = (shift) =>
    AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate',
      { form: { collection: collections.dutiesCollections.shift }, data: shift }, '', 'lg')
  const deleteShift = (shiftId) => {
    if (window.confirm('Are you sure you want to delete this shift?')) {
      meteorCall(Volunteers, 'teamShifts.remove', shiftId)
      reloadShifts()
    }
  }
  const enrollUser = ({ _id: shiftId, policy }) =>
    // TODO Also need to reload shifts and can probably move from autoform modal
    AutoFormComponents.ModalShowWithTemplate('shiftEnrollUsersTable', {
      data: {
        teamId,
        shiftId,
        duty: 'shift',
        policy,
      },
    })
  const unEnrollUser = (signupId) => {
    meteorCall(Volunteers, 'signups.remove', signupId)
    reloadShifts()
  }
  const editRota = (rotaId) => {
    meteorCall(Volunteers, 'rotas.findOne', { rotaId }, (err, rota) => {
      if (err) console.error(err)
      AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate', {
        form: {
          collection: collections.rotas,
        },
        data: rota,
      }, '', 'lg')
    })
  }
  AutoForm.addHooks([
    'InsertRotasFormId',
    'UpdateRotasFormId',
    'UpdateTeamShiftsFormId',
  ], {
    onSuccess() {
      reloadShifts()
      AutoFormComponents.modalHide()
    },
  })

  const [modalUserId, setModalUserId] = useState('')

  return (
    <table className="table">
      <Modal
        title={t('user_details')}
        isOpen={!!modalUserId}
        closeModal={() => setModalUserId('')}
      >
        <UserInfoComponent userId={modalUserId} />
      </Modal>
      {isLoaded && Object.entries(shiftGroups).map(([rotaId, shifts]) => (
        <Fragment key={rotaId}>
          <thead className="thead-default">
            <tr className="shiftFamily table-active">
              <td colSpan="4"><h5>{shifts[0].title}</h5></td>
              <td>
                <button type="button" className="btn btn-light btn-sm" onClick={() => editRota(rotaId)}>
                  <FontAwesomeIcon icon="pen-to-square" /> <T>edit_group</T>
                </button>
              </td>
              {/* <!-- <td>
                <button type="button" className="btn btn-light btn-sm"
                  data-id="" data-type="shift" data-action="add_date">
                  <Fa name="calendar" /> <T>add_date</T>
                </button>
              </td> -->
      <!--        <td>
                <button type="button" className="btn btn-light btn-sm"
                  data-groupid="{{family.rotaId}}" data-parentid="{{_id}}"
                  data-type="shift" data-action="delete_group">
                  <Fa name="trash-o" /> <T>delete_rota</T>
                </button>
              </td>
      --> */}
            </tr>
          </thead>
          <tbody>
            {shifts.map((shift) => (
              <Fragment key={shift._id}>
                <tr>
                  <th scope="row">
                    {/* <!-- #{{shift.rotaId}} --> */}
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
                        onClick={() => enrollUser(shift)}
                      >
                        <FontAwesomeIcon icon="user-plus" />
                      </button>
                    </div>
                  </td>
                </tr>
                {shift.confirmed > 0 && (
                  <tr>
                    <td colSpan="4">
                      <table className="table table-borderless">
                        <tbody>
                          {shift.signups.map((signup, index) => (
                            <tr key={signup._id}>
                              <td>
                                {index + 1}
                                {signup.enrolled && (
                                  <small title={t('voluntold')}>
                                    <FontAwesomeIcon icon="people-pulling" />
                                  </small>
                                )}
                              </td>
                              <td>
                                <button
                                  type="button"
                                  className="btn btn-link"
                                  onClick={() => setModalUserId(signup.userId)}
                                >
                                  {getUsername(users, signup.userId)}
                                </button>
                              </td>
                              <td>
                                <button
                                  type="button"
                                  className="btn btn-sm btn-circle"
                                  onClick={() => unEnrollUser(signup._id)}
                                >
                                  <FontAwesomeIcon icon="trash-alt" />
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </td>
                  </tr>
                )}
              </Fragment>
            ))}
          </tbody>
        </Fragment>
      ))}
    </table>
  )
}
