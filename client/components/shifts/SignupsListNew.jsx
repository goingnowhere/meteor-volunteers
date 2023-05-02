import React, { useContext } from 'react'
import { SignupsListItem } from './SignupsListItem.jsx'
import { reactContext } from '../../clientInit'
import { useMethodCallData } from '../../utils/useMethodCallData'

export function SignupsList({
  dutyType, filters = {},
}) {
  const { methods } = useContext(reactContext)

  const [projects, isLoaded] = useMethodCallData(methods.listOpenShifts, { type: dutyType })

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
      {isLoaded && filteredList.map((project) => (
        <div key={project._id} className="px-2 pb-0 signupsListItem">
          <SignupsListItem key={project._id} type="project" duty={project} />
        </div>
      ))}
    </div>
  )
}
