import { initOrgUnitMethods } from './orgUnitMethods'
import { initSignupMethods } from './signupMethods'
import { initDutiesMethods } from './dutiesMethods'
import { initVolunteerformMethods } from './volunteerFormMethods'
import { initRotaMethods } from './rotaMethods'
import { initPrevEventMethods } from './prevEventMethods'

export const initMethods = (volunteersClass) => {
  const orgUnitMethods = initOrgUnitMethods(volunteersClass)
  initDutiesMethods(volunteersClass)
  initSignupMethods(volunteersClass)
  initVolunteerformMethods(volunteersClass)
  const prevEvent = initPrevEventMethods(volunteersClass)

  const { methodBodies } = initRotaMethods(volunteersClass)

  return {
    methodBodies,
    prevEvent,
    ...orgUnitMethods,
  }
}
