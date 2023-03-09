import React, { useState, useEffect, useContext } from 'react'
import { AutoFormComponents } from 'meteor/abate:autoform-components'
import { AutoForm } from 'meteor/aldeed:autoform'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { T, t } from '../common/i18n'
import { Modal } from '../common/Modal.jsx'
import { formatDate } from '../common/dates'
import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { ProjectStaffingDisplay } from '../common/ProjectStaffingDisplay.jsx'
import { reactContext } from '../../clientInit'
import { meteorCall } from '../../utils/methodUtils'
import { ProjectSignupForm } from '../shifts/ProjectSignupForm.jsx'
import { useMethodCallData } from '../../utils/useMethodCallData'
import { displayName } from '../../../both/utils/helpers'

const getUsername = (users, userId) => {
  const user = users?.find((usr) => usr._id === userId)
  return user && displayName(user)
}

// used to display all shifts for a given team
export const TeamProjectsTable = ({
  reloadRef = {},
  teamId,
  UserInfoComponent,
}) => {
  const Volunteers = useContext(reactContext)
  const { collections, eventName } = Volunteers

  const [{ users, duties: allProjects }, isLoaded, reloadShifts] = useMethodCallData(
    `${eventName}.Volunteers.getTeamDutyStats`,
    { type: 'project', teamId },
  )

  // Hack to allow reloading from above, remove when adding state management
  useEffect(() => {
    reloadRef.current = reloadShifts
    return () => { reloadRef.current = null }
  }, [reloadShifts, reloadRef])

  const editProject = (project) =>
    // TODO Also need to reload projects when no longer using autoform modal
    AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate',
      { form: { collection: collections.dutiesCollections.project }, data: project }, '', 'lg')
  const deleteProject = (projectId) => {
    if (window.confirm('Are you sure you want to delete this project?')) {
      meteorCall(Volunteers, 'projects.remove', projectId)
      reloadShifts()
    }
  }
  const enrollUser = ({
    _id: shiftId,
    policy,
    start,
    end,
  }) =>
    AutoFormComponents.ModalShowWithTemplate('projectEnrollUsersTable', {
      data: {
        teamId,
        shiftId,
        duty: 'project',
        policy,
        start,
        end,
      },
    })
  const unEnrollUser = (signupId) => {
    meteorCall(Volunteers, 'signups.remove', signupId)
    reloadShifts()
  }

  AutoForm.addHooks([
    'InsertProjectsFormId',
    'UpdateProjectsFormId',
  ], {
    onSuccess() {
      reloadShifts()
      AutoFormComponents.modalHide()
    },
  })

  const [modalUserId, setModalUserId] = useState('')
  const [editModal, openEditModal] = useState({})

  return (
    <table className="table">
      <Modal
        title={t('user_details')}
        isOpen={!!modalUserId}
        closeModal={() => setModalUserId('')}
      >
        <UserInfoComponent userId={modalUserId} />
      </Modal>
      <Modal
        isOpen={!!editModal.projectEnrollment}
        closeModal={() => openEditModal({})}
        title={`${editModal?.projectEnrollment?.project?.title}: ${getUsername(users, editModal?.projectEnrollment?.signup.userId)}`}
      >
        <ProjectSignupForm
          project={editModal?.projectEnrollment?.project}
          signup={editModal?.projectEnrollment?.signup}
          onSubmit={() => {
            openEditModal({})
            reloadShifts()
          }}
        />
      </Modal>
      {isLoaded && allProjects.length === 0 && <tbody><tr><td><T>no_projects</T></td></tr></tbody>}
      {isLoaded && allProjects.map((project) => (
        <tbody key={project._id}>
          <tr>
            <td>
              {project.priority === 'essential' && (
                <span className="text-danger"><FontAwesomeIcon icon="exclamation-circle" /></span>
              )}
              {project.policy === 'private' && <FontAwesomeIcon icon="user-secret" />}
              {project.policy === 'requireApproval' && <FontAwesomeIcon icon="lock" />}
              {project.policy === 'adminOnly' && <FontAwesomeIcon icon="user-secret" />}
            </td>
            <td><ProjectDateInline start={project.start} end={project.end} /></td>
            <td>{project.title}</td>
            <td>
              <div className="btn-group inline pull-left">
                <button
                  type="button"
                  className="btn btn-sm btn-circle"
                  onClick={() => editProject(project)}
                >
                  <FontAwesomeIcon icon="pen-to-square" />
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-circle"
                  onClick={() => deleteProject(project._id)}
                >
                  <FontAwesomeIcon icon="trash-alt" />
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-circle"
                  onClick={() => enrollUser(project)}
                >
                  <FontAwesomeIcon icon="user-plus" />
                </button>
              </div>
            </td>
          </tr>
          <tr>
            <td colSpan="4">
              <ProjectStaffingDisplay staffing={project.staffingStats} />
            </td>
          </tr>
          { project.confirmed > 0 && (
            <tr>
              <td colSpan="4">
                <table className="table">
                  <thead>
                    <tr>
                      <th scope="col">#</th>
                      <th scope="col"><T>name</T></th>
                      <th scope="col"><T>arrival</T></th>
                      <th scope="col"><T>departure</T></th>
                      {/* eslint-disable-next-line jsx-a11y/control-has-associated-label */}
                      <th scope="col" />
                    </tr>
                  </thead>
                  <tbody>
                    {project.signups.map((signup, index) => (
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
                        <td>{formatDate(signup.start)}</td>
                        <td>{formatDate(signup.end)}</td>
                        <td>
                          <div className="btn-group inline pull-left">
                            <button
                              type="button"
                              title="edit"
                              className="btn btn-sm btn-circle"
                              onClick={() => openEditModal({
                                projectEnrollment: { project, signup },
                              })}
                            >
                              <FontAwesomeIcon icon="pen-to-square" />
                            </button>
                            <button
                              type="button"
                              title="remove"
                              className="btn btn-sm btn-circle"
                              onClick={() => unEnrollUser(signup._id)}
                            >
                              <FontAwesomeIcon icon="trash-alt" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </td>
            </tr>
          )}
        </tbody>
      ))}
    </table>
  )
}
