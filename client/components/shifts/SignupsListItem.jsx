import React from 'react'

import { T } from '../common/i18n'
import { DutiesListItem } from './DutiesListItem.jsx'
import { SignupProjectRow } from './SignupProjectRow.jsx'

export const SignupsListItem = ({ duty, showSignupModal }) => {
  return (
    <>
      <DutiesListItem duty={duty} />
      <div className="row no-gutters pt-2 align-items-center">
        {duty.type === 'project'
          ? <SignupProjectRow duty={duty} showSignupModal={showSignupModal} />
          : (
            <>
              <div className="col">
                <div className="btn-action">
                  <h5 className="mb-0">{ duty.length } <T>shift_length_hours</T></h5>
                </div>
              </div>
              <div className="col">
                <button
                  className="btn btn-action btn-primary"
                  type="button"
                  onClick={() => showSignupModal(duty)}
                >
                  <T>choose_shifts</T>
                </button>
              </div>
            </>
          )}
      </div>
    </>
  )
}
