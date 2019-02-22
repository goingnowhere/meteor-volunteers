/* eslint-disable no-nested-ternary */
import React, { Fragment } from 'react'

import { T } from '../common/i18n'
import { LeadTitle } from './LeadTitle.jsx'
import { LeadBody } from './LeadBody.jsx'

export const LeadListItem = ({
  lead: {
    team,
    signup = {},
    title,
    policy,
    description,
    responsibilities,
    qualifications,
  },
  apply,
}) => (
  <Fragment>
    <div className="row justify-content-between align-content-center no-gutters">
      <div className="col-lg-6 col-md-8 col-sm-10">
        <LeadTitle team={team} />
      </div>
      <div className="col">
        {signup.status && signup.status !== 'bailed' ? (
          <button
            className={`btn btn-light btn-action disabled ${
              signup.status === 'confirmed' ? 'btn-success' : ''
            }`}
            type="button"
          >
            <T>{signup.status}</T>
          </button>
        ) : policy !== 'adminOnly' ? (
          <button
            className="btn btn-primary btn-action"
            type="button"
            onClick={apply}
          >
            {policy === 'public' && <T>join</T>}
            {policy === 'requireApproval' && <T>apply</T>}
          </button>
        ) : (
          <div><T>admin_only</T></div>
        )}
      </div>
    </div>
    <div className="row">
      <div className="col">
        <LeadBody
          title={title}
          description={description}
          responsibilities={responsibilities}
          qualifications={qualifications}
        />
      </div>
    </div>
  </Fragment>
)
