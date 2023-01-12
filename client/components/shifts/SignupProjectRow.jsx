import React from 'react'

import { ProjectDate } from '../common/ProjectDate.jsx'
import { SignupProjectButtons } from './SignupProjectButtons.jsx'

export const SignupProjectRow = ({
  duty,
  showSignupModal,
}) => {
  return (
    <>
      <ProjectDate start={duty.start} end={duty.end} />
      <div className="col p-0">
        {duty.signup && duty.signup.status !== 'bailed' ? (
          // TODO Change button contents based on project signups
          null
        ) : <SignupProjectButtons duty={duty} showSignupModal={showSignupModal} />}
      </div>
    </>
  )
}
