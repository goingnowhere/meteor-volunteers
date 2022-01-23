import { collections } from '../collections/initCollections'
import { createOrgUnitMethods } from './orgUnitMethods'
import { createSignupMethods } from './signupMethods'
import { createDutiesMethod } from './dutiesMethods'
import { createVolunteerformMethods } from './volunteerFormMethods'
import { createRotaMethods } from './rotaMethods'

export const initMethods = (eventName) => {
  Object.values(collections.orgUnitCollections).forEach(orgUnitColl => {
    createOrgUnitMethods(orgUnitColl)
  })
  Object.values(collections.dutiesCollections).forEach(dutyColl => {
    createDutiesMethod(dutyColl)
  })

  createSignupMethods(eventName)

  createVolunteerformMethods(eventName)

  const { methodBodies } = createRotaMethods(eventName)

  return { methodBodies }
}
