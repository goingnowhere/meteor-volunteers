import { _ } from 'meteor/underscore'
import { collections } from '../collections/initCollections'

export const getSkillsList = (sel = {}) =>
  _.union(...collections.team.find(sel, { fields: { skills: true } }).map(team => team.skills))
    .filter(item => item)
    .map(tag => ({ value: tag, label: tag }))

export const getQuirksList = (sel = {}) =>
  _.union(...collections.team.find(sel, { fields: { quirks: true } }).map(team => team.quirks))
    .filter(item => item)
    .map(tag => ({ value: tag, label: tag }))

export const getLocationList = (sel = {}) =>
  _.union(...collections.team.find(sel, { fields: { location: true } }).map(team => team.location))
    .filter(item => item)
    .map(loc => ({ value: loc, label: loc }))

export const findOrgUnit = (unitId) => {
  const team = collections.team.findOne({ _id: unitId })
  if (team) {
    return {
      unit: team,
      type: 'team',
    }
  }
  const dept = collections.department.findOne({ _id: unitId })
  if (dept) {
    return {
      unit: dept,
      type: 'department',
    }
  }
  const div = collections.division.findOne({ _id: unitId })
  if (div) {
    return {
      unit: div,
      type: 'division',
    }
  }
  return {}
}
