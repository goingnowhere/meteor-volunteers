/* globals __coffeescriptShare */
import React from 'react'

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

// TODO generalise this for any signup, not just leads
export const SignupApproval = ({
  signup: {
    _id,
    duty,
    user,
    team,
    dept,
  },
  isTeam,
  openUserModal,
  reloadSignups,
}) => (
  <li className="list-group-item p-2">
    <div className="row no-gutters align-items-center">
      <div className="col">
        {!isTeam && `${(dept && dept.name) || (team && team.name)}  > `}{ duty.title }
        {/* {{#if $eq signup.type 'shift'}}
          <div>
            {{> React component=ShiftDateInline start=signup.duty.start end=signup.duty.end }}
          </div>
        {{/if}}
        {{#if $eq signup.type 'project'}}
          <div>
            {{> React component=ProjectDateInline start=signup.start end=signup.end }}
          </div>
        {{/if}}
        {{#if $eq signup.type 'task'}}
          {{> taskDate signup.duty }}
        {{/if}} */}
      </div>
      <div className="col" data-action="user-info" data-id="{{ signup.userId }}">
        <button type="button" className="btn btn-link" onClick={() => openUserModal(user._id)}>
          {user.profile.nickname || user.profile.firstName}
        </button>
        {/* XXX to be fixed */}
        {/* <small>{{__ ".created"}}: {{createdAgo signup.createdAt}}</small> */}
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
