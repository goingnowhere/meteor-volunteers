import React, { useContext, useState } from 'react'
import { SignupsListItem } from './SignupsListItem.jsx'
import { reactContext } from '../../clientInit'
import { useMethodCallData } from '../../utils/useMethodCallData'
import { Modal } from '../common/Modal.jsx'
import { ShiftSignupModalContents } from './ShiftSignupModalContents.jsx'
import { ProjectSignupForm } from './ProjectSignupForm.jsx'

export function SignupsList({
  dutyType, filters = {},
}) {
  const { methods } = useContext(reactContext)

  const [projects, isLoaded] = useMethodCallData(methods.listOpenShifts, { type: dutyType })

  const [signupDuty, setSignupDuty] = useState()

  if (!['build-strike', 'build', 'strike'].includes(dutyType)) {
    // TODO implement shift version for event-time and include shifts in build/strike
    return <p>Not Yet Implemented</p>
  }

  // Since we load with all data it's more efficient to filter on the front-end instead of querying
  // more. If we add deep-linking to filters maybe it would make sense to change this.
  let filteredList = projects
  if (filters.quirks?.length > 0) {
    filteredList = filteredList.filter(({ quirks }) =>
      filters.quirks.some((filtered) => quirks.includes(filtered)))
  }
  if (filters.skills?.length > 0) {
    filteredList = filteredList.filter(({ skills }) =>
      filters.skills.some((filtered) => skills?.includes(filtered)))
  }

  return (
    <div className="container-fluid p-0">
      <Modal isOpen={!!signupDuty} closeModal={() => setSignupDuty(null)} title={signupDuty?.title}>
        {signupDuty?.type === 'project'
          ? <ProjectSignupForm project={signupDuty} onSubmit={setSignupDuty} />
          : <ShiftSignupModalContents duty={signupDuty} />}
      </Modal>
      {isLoaded && filteredList.map((project) => (
        <div key={project._id} className="px-2 pb-0 signupsListItem">
          <SignupsListItem duty={project} showSignupModal={setSignupDuty} />
        </div>
      ))}
    </div>
  )
}
