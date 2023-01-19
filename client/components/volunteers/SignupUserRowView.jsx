import React, { useContext, useState } from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { useTracker } from 'meteor/react-meteor-data'

import { t, T } from '../common/i18n'
import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { bailCall } from '../../utils/signups'
import { Modal } from '../common/Modal.jsx'
import { DutiesListItem } from '../shifts/DutiesListItem.jsx'
import { reactContext } from '../../clientInit'

export const SignupUserRowView = ({
  signup = {},
  editProject,
}) => {
  const Volunteers = useContext(reactContext)
  const { team, duty, editProjectClick } = useTracker(() => {
    const orgUnit = Volunteers.collections.utils.findOrgUnit(signup.parentId)
    return {
      team: orgUnit ? orgUnit.unit : {},
      duty: Volunteers.collections.dutiesCollections[signup.type].findOne(signup.shiftId),
      editProjectClick: () => editProject({ project: duty, signup }),
    }
  }, [signup, editProject])
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
            {signup.type === 'shift' && <ShiftDateInline start={duty.start} end={duty.end} />}
          </div>
          <div className="col">
            <h6>{team.name} &gt; {duty.title}</h6>
          </div>
        </div>
        <div className="row px-1 py-0">
          <div className="col">
            {signup.status === 'confirmed' && <div className="text-success"><FontAwesomeIcon icon="check" /> <T>confirmed</T></div>}
            {signup.status === 'pending' && <div className="text-warning"><FontAwesomeIcon icon="clock" /> <T>pending</T></div>}
          </div>
          <div className="col px-1 py-0" />

          <div className="col px-1 py-0">
            <button type="button" onClick={() => showModal(true)} className="btn btn-primary btn-action">
              <T>info</T>
            </button>
          </div>

          {signup.type === 'project' && (
            <div className="col px-1 py-0">
              <button type="button" onClick={editProjectClick} className="btn btn-primary btn-action">
                <T>change_dates</T>
              </button>
            </div>
          )}

          <div className="col px-0">
            <button
              type="button"
              onClick={bailCall(Volunteers, signup)}
              className="btn btn-primary btn-action"
            >
              <T>bail</T>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
