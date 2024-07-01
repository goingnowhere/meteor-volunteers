import React, { useContext, useState } from 'react'
import { SignupsListItem } from './SignupsListItem.jsx'
import { reactContext } from '../../clientInit'
import { useMethodCallData } from '../../utils/useMethodCallData'
import { Modal } from '../common/Modal.jsx'
import { RotaSignupForm } from './RotaSignupForm.jsx'
import { ProjectSignupForm } from './ProjectSignupForm.jsx'

export function SignupsList({
  dutyType = 'all', filters = {},
}) {
  const { methods } = useContext(reactContext)

  let [filteredList, isLoaded] = useMethodCallData(methods.listOpenShiftsByPref, {
    type: dutyType,
    teams: filters.teams,
  }, { default: [] })

  const [modalSignupDuty, setModalSignup] = useState()
  const [changedRotas, setChangedRotas] = useState({})
  const onSignupChange = (signupInfo) => {
    setChangedRotas({ ...changedRotas, [signupInfo.rotaInfo._id]: signupInfo.rotaInfo })
  }

  // Since we load with all data it's more efficient to filter on the front-end instead of querying
  // more. If we add deep-linking to filters maybe it would make sense to change this.
  if (filters.quirks?.length > 0) {
    filteredList = filteredList.filter(({ quirks }) =>
      filters.quirks.some((filtered) => quirks?.includes(filtered)))
  }
  if (filters.skills?.length > 0) {
    filteredList = filteredList.filter(({ skills }) =>
      filters.skills.some((filtered) => skills?.includes(filtered)))
  }
  if (filters.priorities?.length > 0) {
    filteredList = filteredList.filter(({ priority }) =>
      filters.priorities.includes(priority))
  }

  return (
    <div className="container-fluid p-0">
      <Modal isOpen={!!modalSignupDuty} closeModal={() => setModalSignup(null)} title={modalSignupDuty?.title}>
        {modalSignupDuty && (modalSignupDuty?.type === 'project'
          ? <ProjectSignupForm project={modalSignupDuty} onSubmit={setModalSignup} />
          : <RotaSignupForm duty={changedRotas[modalSignupDuty._id] ?? modalSignupDuty} onChange={onSignupChange} />)}
      </Modal>
      {isLoaded && filteredList.map((project) => (
        <div key={project._id} className="px-2 pb-0 signupsListItem">
          <SignupsListItem duty={project} showSignupModal={setModalSignup} />
        </div>
      ))}
    </div>
  )
}
