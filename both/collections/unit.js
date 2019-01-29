/* globals __coffeescriptShare */
import { _ } from 'meteor/underscore'

const share = __coffeescriptShare

export const getSkillsList = (sel = {}) =>
  _.union(...share.Team.find(sel).map(team => team.skills))
    .filter(item => item)
    .map(tag => ({ value: tag, label: tag }))

export const getQuirksList = (sel = {}) =>
  _.union(...share.Team.find(sel).map(team => team.quirks))
    .filter(item => item)
    .map(tag => ({ value: tag, label: tag }))

export const getLocationList = (sel = {}) =>
  _.union(...share.Team.find(sel).map(team => team.location))
    .filter(item => item)
    .map(loc => ({ value: loc, label: loc }))
