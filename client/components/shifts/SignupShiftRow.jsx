import React, { useContext } from 'react'

import { T } from '../common/i18n'
import { ShiftDate } from '../common/ShiftDate.jsx'
import { bailCall } from '../../utils/signups'
import { SignupShiftButtons } from './SignupShiftButtons.jsx'
import { reactContext } from '../../clientInit'

export const SignupShiftRow = ({
  start,
  end,
  signup,
  ...duty
}) => {
  const Volunteers = useContext(reactContext)
  return (
    <>
      <ShiftDate start={start} end={end} />
      <div className="col p-0">
        {signup && signup.status !== 'bailed' ? (
          <div className="d-flex">
            <button
              className={`btn btn-action disabled
                ${signup.status === 'confirmed' ? 'btn-success' : ''}`}
              type="button"
            >
              <T>{signup.status}</T>
            </button>
            <button
              className="btn btn-primary btn-action"
              type="button"
              onClick={bailCall(Volunteers, { ...duty })}
            >
              <T>cancel</T>
            </button>
          </div>
        ) : <SignupShiftButtons {...duty} />}
      </div>
    </>
  )
}
