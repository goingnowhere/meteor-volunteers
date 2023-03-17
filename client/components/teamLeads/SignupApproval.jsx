import React, { useContext } from 'react'
import moment from 'moment-timezone'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { reactContext } from '../../clientInit'
import { meteorCall } from '../../utils/methodUtils'
import { ProjectDateInline } from '../common/ProjectDateInline.jsx'
import { ShiftDateInline } from '../common/ShiftDateInline.jsx'
import { T } from '../common/i18n'

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
  reload,
}) => {
  const Volunteers = useContext(reactContext)
  const approve = () => {
    meteorCall(Volunteers, 'signups.confirm', _id)
    reload()
  }
  const refuse = () => {
    meteorCall(Volunteers, 'signups.refuse', _id)
    reload()
  }
  return (
    <li className="list-group-item p-2">
      <div className="row no-gutters align-items-center">
        <div className="col">
          {type === 'lead'
            ? `${(dept && dept.name) || (team && team.name)}${duty?.title ? `  > ${duty.title}` : ''}`
            : duty.title}
          <div>
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
        </div>
        <div className="col" data-action="user-info" data-id="{{ signup.userId }}">
          {!user ? (
            <p>Bug detected... hiding this for now</p>
          ) : (
            <button type="button" className={`btn btn-link${user.ticketId ? '' : ' text-danger'}`} onClick={() => openUserModal(user._id)}>
              {!user.ticketId && (<FontAwesomeIcon icon="warning" title="No Ticket!" />)}
              {user.profile.nickname || user.profile.firstName}
            </button>
          )}
          <small><T>created</T>: {createdAt && moment(createdAt).fromNow()}</small>
        </div>
        <div className="col">
          <button type="button" className="btn btn-light btn-sm" onClick={approve}>
            <T>approve</T>
          </button>
          <button type="button" className="btn btn-light btn-sm" onClick={refuse}>
            <T>refuse</T>
          </button>
        </div>
      </div>
    </li>
  )
}
