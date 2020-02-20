/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import React, { useState, useEffect } from 'react'
import Fa from 'react-fontawesome'
import { AutoFormComponents } from 'meteor/abate:autoform-components'
import { AutoForm } from 'meteor/aldeed:autoform'

import { T, t } from '../common/i18n'
import { Modal } from '../common/Modal.jsx'
import { formatDate } from '../common/dates'
import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { collections } from '../../../both/collections/initCollections'
import { ProjectStaffingDisplay } from '../common/ProjectStaffingDisplay.jsx'

const getUsername = (users, userId) => {
  const user = users.find((usr) => usr._id === userId)
  return user && (user.profile.nickname || user.profile.firstName)
}

const share = __coffeescriptShare

// used to display all shifts for a given team
export const TeamProjectsTable = ({ teamId, UserInfoComponent }) => {
  const [users, setUsers] = useState([])
  const [allProjects, setProjects] = useState([])
  const reloadShifts = () => Meteor.call(`${share.eventName}.Volunteers.getTeamDutyStats`,
    { type: 'project', teamId }, (err, { users: usrs, duties }) => {
      if (err) console.error(err)
      else {
        setUsers(usrs)
        setProjects(duties)
      }
    })
  useEffect(reloadShifts, [teamId])

  const editProject = (project) =>
    // TODO Also need to reload projects when no longer using autoform modal
    AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate',
      { form: { collection: collections.dutiesCollections.project }, data: project }, '', 'lg')
  const deleteProject = (projectId) => {
    if (window.confirm('Are you sure you want to delete this project?')) {
      share.meteorCall('projects.remove', projectId)
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
  const editEnrollment = (project, signup) =>
    AutoFormComponents.ModalShowWithTemplate('projectSignupForm', {
      project,
      signup,
    }, project.title)
  const unEnrollUser = (signupId) => {
    share.meteorCall('signups.remove', signupId)
    reloadShifts()
  }

  AutoForm.addHooks([
    'InsertProjectsFormId',
    'UpdateProjectsFormId',
    'projectSignupsUpdate',
    'projectSignupsInsert',
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
      {/* i18n! */}
      {allProjects.length === 0 && <tbody><tr><td>No projects here...</td></tr></tbody>}
      {allProjects.map((project) => (
        <tbody key={project._id}>
          <tr>
            <td>
              {project.priority === 'essential' && (
                <span className="text-danger"><Fa name="exclamation-circle" /></span>
              )}
              {project.policy === 'private' && <Fa name="user-secret" />}
              {project.policy === 'requireApproval' && <Fa name="lock" />}
              {project.policy === 'adminOnly' && <Fa name="user-secret" />}
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
                  <Fa name="pencil-square-o" />
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-circle"
                  onClick={() => deleteProject(project._id)}
                >
                  <Fa name="trash-o" />
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-circle"
                  onClick={() => enrollUser(project)}
                >
                  <Fa name="user-plus" />
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
                        <td>{formatDate(signup.start)}</td>
                        <td>{formatDate(signup.end)}</td>
                        <td>
                          <div className="btn-group inline pull-left">
                            <button
                              type="button"
                              title="edit"
                              className="btn btn-sm btn-circle"
                              onClick={() => editEnrollment(project, signup)}
                            >
                              <Fa name="pencil-square-o" />
                            </button>
                            <button
                              type="button"
                              title="remove"
                              className="btn btn-sm btn-circle"
                              onClick={() => unEnrollUser(signup._id)}
                            >
                              <Fa name="trash-o" />
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
