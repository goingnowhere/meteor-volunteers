import React, { useState } from 'react'
import Fa from 'react-fontawesome'
import { withTracker } from 'meteor/react-meteor-data'
import { AutoFormComponents } from 'meteor/abate:autoform-components'

import { t, T } from '../common/i18n'
import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { bailCall } from '../../utils/signups'
import { collections } from '../../../both/collections/initCollections'
import { findOrgUnit } from '../../../both/collections/unit'
import { Modal } from '../common/Modal.jsx'
import { DutiesListItem } from '../shifts/DutiesListItem.jsx'

export const SignupUserRowViewComponent = ({
  signup = {},
  team = {},
  duty = {},
  editProject,
  bail,
}) => {
  const [modalOpen, showModal] = useState(false)
  return (
    <div className={`row no-gutters ${signup.status !== 'confirmed' ? 'text-muted' : ''}`} title={t(signup.status)}>
      <Modal isOpen={modalOpen} closeModal={() => showModal(false)} title={duty.title}>
        <DutiesListItem type={signup.type} duty={duty} team={team} />
      </Modal>
      <div className="container-fluid">
        <div className="row p-2">
          <div className="col">
            {signup.type === 'lead' && team.name}
            {signup.type === 'project' && <ProjectDateInline start={signup.start} end={signup.end} />}
            {signup.type === 'shift' && <ShiftDateInline start={signup.start} end={signup.end} />}
          </div>
          <div className="col">
            <h6>{team.name} &gt; {duty.title}</h6>
          </div>
        </div>
        <div className="row px-1 py-0">
          <div className="col">
            {signup.status === 'confirmed' && <div className="text-success"><Fa name="check" /> <T>confirmed</T></div>}
            {signup.status === 'pending' && <div className="text-warning"><Fa name="clock-o" /> <T>pending</T></div>}
          </div>
          <div className="col px-1 py-0" />

          <div className="col px-1 py-0">
            <button type="button" onClick={() => showModal(true)} className="btn btn-primary btn-action">
              <T>info</T>
            </button>
          </div>

          {signup.type === 'project' && (
            <div className="col px-1 py-0">
              <button type="button" onClick={editProject} className="btn btn-primary btn-action">
                <T>change_dates</T>
              </button>
            </div>
          )}

          <div className="col px-0">
            <button type="button" onClick={bail} className="btn btn-primary btn-action">
              <T>bail</T>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

const editProject = ({ duty, signup }) => () => {
  AutoFormComponents.ModalShowWithTemplate('projectSignupForm', { project: duty, signup })
}

export const SignupUserRowView = withTracker(({ signup }) => {
  const orgUnit = findOrgUnit(signup.parentId)
  const team = orgUnit ? orgUnit.unit : {}
  const duty = collections.dutiesCollections[signup.type].findOne(signup.shiftId)
  return {
    signup,
    team,
    duty,
    editProject: editProject({ duty, signup }),
    bail: bailCall(signup),
  }
})(SignupUserRowViewComponent)
