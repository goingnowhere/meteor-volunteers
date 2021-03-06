/* globals __coffeescriptShare */
import React from 'react'
import moment from 'moment-timezone'
import Fa from 'react-fontawesome'

import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { T } from '../common/i18n'

const share = __coffeescriptShare

const approve = (signupId, reload) => {
  share.meteorCall('signups.confirm', signupId)
  reload()
}

const refuse = (signupId, reload) => {
  share.meteorCall('signups.refuse', signupId)
  reload()
}

export const SignupApproval = ({
  signup: {
    _id,
    duty,
    user,
    team,
    dept,
    type,
    start,
    end,
    createdAt,
  },
  openUserModal,
  reloadSignups,
}) => (
  <li className="list-group-item p-2">
    <div className="row no-gutters align-items-center">
      <div className="col">
        {type === 'lead'
          ? `${(dept && dept.name) || (team && team.name)}  > ${duty.title}`
          : duty.title}
        {type === 'shift' && (
          <ShiftDateInline start={duty.start} end={duty.end} />
        )}
        {type === 'project' && (
          <ProjectDateInline key={_id} start={start} end={end} />
        )}
        {/* TODO {type === 'task' && (
          <TaskDateInline due={duty.dueDate} />
        )} */}
      </div>
      <div className="col" data-action="user-info" data-id="{{ signup.userId }}">
        <button type="button" className={`btn btn-link${user.ticketId ? '' : ' text-danger'}`} onClick={() => openUserModal(user._id)}>
          {!user.ticketId && (<Fa name="warning" title="No Ticket!" />)}
          {user.profile.nickname || user.profile.firstName}
        </button>
        <small><T>created</T>: {createdAt && moment(createdAt).fromNow()}</small>
      </div>
      <div className="col">
        <button type="button" className="btn btn-light btn-sm" onClick={() => approve(_id, reloadSignups)}>
          <T>approve</T>
        </button>
        <button type="button" className="btn btn-light btn-sm" onClick={() => refuse(_id, reloadSignups)}>
          <T>refuse</T>
        </button>
      </div>
    </div>
  </li>
)
