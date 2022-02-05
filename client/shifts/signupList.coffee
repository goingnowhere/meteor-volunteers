import SimpleSchema from 'simpl-schema'
import { LeadListItemGrouped } from '../components/shifts/LeadListItemGrouped.jsx'
import { SignupsListTeam } from '../components/volunteers/SignupsListTeam.jsx'
import { collections } from '../../both/collections/initCollections'

templateSub = (template,name,args...) ->
  template.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

Template.signupsList.bindI18nNamespace('goingnowhere:volunteers')
Template.signupsList.onCreated () ->
  template = this
  template.limit = new ReactiveVar(4)
  quirks =  template.data?.quirks
  skills =  template.data?.skills

  template.autorun () ->
    limit = template.limit.get()
    if quirks and skills
      templateSub(template,"team.ByUserPref",quirks,skills,limit)
    else
      templateSub(template,"team")

Template.signupsList.helpers
  LeadListItemGrouped: () -> LeadListItemGrouped,
  SignupsListTeam: () -> SignupsListTeam,
  'allTeams': () ->
    template = Template.instance()
    limit = template.limit.get()
    filters = template.data?.filters
    query = {}
    query.skills = {$in: filters.skills} if filters?.skills?
    query.quirks = {$in: filters.quirks} if filters?.quirks?
    # teams are ordered using the score that is calculated by considering
    # the priority of the shifts associated with each team
    return collections.team
      .find(query,{sort: {userpref: -1, score: -1}, limit:limit})
  'loadMore' : () ->
    template = Template.instance()
    collections.team.find().count() >= template.limit.get()

Template.signupsList.events
  'click [data-action="loadMoreTeams"]': ( event, template ) ->
    event.preventDefault()
    limit = template.limit.get()
    template.limit.set(limit+2)
