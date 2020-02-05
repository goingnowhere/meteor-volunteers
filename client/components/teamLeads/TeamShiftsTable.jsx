/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { _ } from 'meteor/underscore'
import React, { Fragment, useState, useEffect } from 'react'
import Fa from 'react-fontawesome'
import { AutoFormComponents } from 'meteor/abate:autoform-components'

import { T, t } from '../common/i18n'
import { Modal } from '../common/Modal.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { collections } from '../../../both/collections/initCollections'

const getUsername = (users, userId) => {
  const user = users.find((usr) => usr._id === userId)
  return user && (user.profile.nickname || user.profile.firstName)
}

const share = __coffeescriptShare

// used to display all shifts for a given team
export const TeamShiftsTable = ({ date, teamId, UserInfoComponent }) => {
  const [users, setUsers] = useState([])
  const [shiftGroups, setShifts] = useState([])
  const reloadShifts = () => Meteor.call(`${share.eventName}.Volunteers.getTeamDutyStats`,
    { type: 'shift', teamId, date: date && date.toDate() }, (err, { users: usrs, duties }) => {
      if (err) console.error(err)
      else {
        setUsers(usrs)
        const groupedDuties = _.groupBy(duties, 'groupId')
        setShifts(groupedDuties)
      }
    })
  useEffect(reloadShifts, [teamId, date])

  const editShift = (shift) =>
    // TODO Also need to reload shifts when no longer using autoform modal
    AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate',
      { form: { collection: collections.dutiesCollections.shift }, data: shift }, '', 'lg')
  const deleteShift = (shiftId) => {
    if (window.confirm('Are you sure you want to delete this shift?')) {
      share.meteorCall('teamShifts.remove', shiftId)
      reloadShifts()
    }
  }
  const enrollUser = ({ _id: shiftId, policy }) =>
    AutoFormComponents.ModalShowWithTemplate('shiftEnrollUsersTable', {
      data: {
        teamId,
        shiftId,
        duty: 'shift',
        policy,
      },
    })
  const unEnrollUser = (signupId) => {
    share.meteorCall('signups.remove', signupId)
    reloadShifts()
  }

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
      {Object.entries(shiftGroups).map(([groupId, shifts]) => (
        <Fragment key={groupId}>
          <thead className="thead-default">
            <tr className="shiftFamily table-active">
              <td colSpan="4"><h5>{shifts[0].title}</h5></td>
              <td>
                <button type="button" className="btn btn-light btn-sm">
                  <Fa name="pencil-square-o" /> <T>edit_group</T>
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
                  data-groupid="{{family.groupId}}" data-parentid="{{_id}}"
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
                        <span className="text-danger"><Fa name="exclamation-circle" /></span>
                      )}
                      {shift.policy === 'private' && <Fa name="user-secret" />}
                      {shift.policy === 'requireApproval' && <Fa name="lock" />}
                      {shift.policy === 'adminOnly' && <Fa name="user-secret" />}
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
                        <Fa name="pencil-square-o" />
                      </button>
                      <button
                        type="button"
                        className="btn btn-sm btn-circle"
                        onClick={() => deleteShift(shift._id)}
                      >
                        <Fa name="trash-o" />
                      </button>
                      <button
                        type="button"
                        className="btn btn-sm btn-circle"
                        onClick={() => enrollUser(shift)}
                      >
                        <Fa name="user-plus" />
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
                                {index}
                                {signup.enrolled && (
                                  <small title={t('voluntold')}>
                                    <Fa name="hand-spock-o" />
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
                                  <Fa name="trash-o" />
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
