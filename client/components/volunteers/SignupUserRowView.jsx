/* global __coffeescriptShare */
import React from 'react'
import Fa from 'react-fontawesome'
import { withTracker } from 'meteor/react-meteor-data'
import { AutoFormComponents } from 'meteor/abate:autoform-components'

import { __ } from '../common/i18n'
import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'

export const SignupUserRowView = ({
  signup,
  team,
  duty,
  editProject,
  showInfo,
  bail,
}) => (
  <div className={`row no-gutters ${signup.status !== 'confirmed' ? 'text-muted' : ''}`} title={__(signup.status)}>
    <div className="container-fluid">
      <div className="row p-2">
        <div className="col">
          {signup.type === 'project' && <ProjectDateInline {...signup} />}
          {signup.type === 'shift' && <ShiftDateInline {...duty} />}
        </div>
        <div className="col">
          <h6>{team.name} &gt; {duty.title}</h6>
        </div>
      </div>
      <div className="row px-1 py-0">
        <div className="col">
          {signup.status === 'confirmed' && <div className="text-success"><Fa name="check" /> {__('confirmed')}</div>}
          {signup.status === 'pending' && <div className="text-warning"><Fa name="clock-o" /> {__('pending')}</div>}
        </div>
        <div className="col px-1 py-0" />

        <div className="col px-1 py-0">
          <button type="button" onClick={showInfo} className="btn btn-primary btn-action">
            {__('info')}
          </button>
        </div>

        {signup.type === 'project' && (
          <div className="col px-1 py-0">
            <button type="button" onClick={editProject} className="btn btn-primary btn-action">
              {__('change_dates')}
            </button>
          </div>
        )}

        <div className="col px-0">
          <button type="button" onClick={bail} className="btn btn-primary btn-action">
            {__('bail')}
          </button>
        </div>
      </div>
    </div>
  </div>
)

const share = __coffeescriptShare

const editProject = ({ duty, signup }) => () => {
  AutoFormComponents.ModalShowWithTemplate('projectSignupForm', { project: duty, signup })
}

const showInfo = ({ duty, team }) => () => {
  // TODO can we modify dutyListItem to take separate team and duty?
  AutoFormComponents.ModalShowWithTemplate('dutyListItem', { ...duty, team })
}

const bail = signup => () => {
  const {
    type,
    parentId,
    shiftId,
    userId,
  } = signup
  share.meteorCall(`${type}Signups.bail`, { parentId, shiftId, userId })
}

export const SignupUserRowViewContainer = withTracker(({ signup }) => {
  const team = share.Team.findOne(signup.parentId)
  const duty = share.dutiesCollections[signup.type].findOne(signup.shiftId)
  return {
    signup,
    team,
    duty,
    editProject: editProject({ duty, signup }),
    showInfo: showInfo({ duty, team }),
    bail: bail(signup),
  }
})(SignupUserRowView)
