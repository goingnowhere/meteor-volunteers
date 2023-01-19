import { initOrgUnitMethods } from './orgUnitMethods'
import { initSignupMethods } from './signupMethods'
import { initDutiesMethods } from './dutiesMethods'
import { initVolunteerformMethods } from './volunteerFormMethods'
import { initRotaMethods } from './rotaMethods'

export const initMethods = (volunteersClass) => {
  initOrgUnitMethods(volunteersClass)
  initDutiesMethods(volunteersClass)
  initSignupMethods(volunteersClass)
  initVolunteerformMethods(volunteersClass)

  const { methodBodies } = initRotaMethods(volunteersClass)

  return { methodBodies }
}
