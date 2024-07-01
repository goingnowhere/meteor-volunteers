import React, { useContext } from 'react'

import { SignupShiftRow } from './SignupShiftRow.jsx'
import { reactContext } from '../../clientInit'

export function RotaSignupForm({
  duty,
  onChange,
}) {
  const Volunteers = useContext(reactContext)
  return (
    <>
      {duty.information && <p>{duty.information}</p>}
      {duty.shiftObjects.map((shift) => (
        <div key={shift._id} className="list-item row align-items-center px-2">
          <SignupShiftRow
            {...shift}
            rotaId={duty._id}
            signup={shift.signups?.userStatuses.find(({ userId }) => userId === Volunteers.userId)}
            type="shift"
            onChange={onChange}
          />
        </div>
      ))}
    </>
  )
}
