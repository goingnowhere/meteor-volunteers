import SimpleSchema from 'simpl-schema'
import { LeadListItemGroupedContainer } from '../components/shifts/LeadListItemGrouped.jsx'
import { DutiesListItemGrouped } from '../components/shifts/DutiesListItemGrouped.jsx'

ShiftTitles = new Mongo.Collection(null)

# coll contains shifts unique shifts title
addLocalDutiesCollection = (team,duties,type,filter,limit) ->
  ShiftTitles.remove({type, parentId: filter.parentId})
  shifts = duties.find(filter,{limit: limit}).fetch()
  _.chain(shifts).groupBy('title').map((shifts,title) ->
    shift = shifts[0]
    duty = {
      type,
      title,
      description: shift.description,
      priority: shift.priority,
      parentId: filter.parentId,
      policy: filter.policy,
      team,
    }
    if type == 'project'
      duty._id = shift._id
      duty.start = shift.start
      duty.end = shift.end
    ShiftTitles.insert(duty)
  ).value()

Template.signupsListTeam.bindI18nNamespace('goingnowhere:volunteers')
Template.signupsListTeam.onCreated () ->
  template = this
  {team, dutyType = ''} = template.data

  template.autorun () ->
    sel = {parentId : team._id}
    # TODO Only need one to get details of the shift but this limits to only one project per team.
    # We should add a 'projectGroups' aggregation in the same way as 'shiftGroups'
    limit = 10
    {filters} = Template.currentData()
    if filters?.priorities?
      sel.priority = {$in: filters.priorities}
    switch dutyType
      when "shift"
        share.templateSub(template,"shiftGroups",sel)
      when "task"
        share.templateSub(template,"TeamTasks",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.TeamTasks,'task',sel,limit)
      when "project"
        share.templateSub(template,"Projects",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.Projects,'project',sel,limit)
      else
        share.templateSub(template,"shiftGroups",sel)
        share.templateSub(template,"TeamTasks",sel,limit)
        share.templateSub(template,"Projects",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.TeamTasks,'task',sel,limit)
          addLocalDutiesCollection(team,share.Projects,'project',sel,limit)

Template.signupsListTeam.helpers
  DutiesListItemGrouped: () -> DutiesListItemGrouped
  'allShifts': () ->
    template = Template.instance()
    {team, dutyType = ''} = template.data
    sel = {parentId : team._id}
    if template.subscriptionsReady()
      shiftGroups = []
      if dutyType in ['lead', 'project']
        sel.type = dutyType
      else
        shiftGroups = share.shiftGroups.find(sel).map(
          (group) -> _.extend(group, {type: 'shift', team})
        )
      otherDuties = ShiftTitles.find(sel).fetch()
      return shiftGroups.concat(otherDuties)
    else []

Template.signupsListTeam.events
  'click [data-action="loadMoreShifts"]': ( event, template ) ->
    event.preventDefault()
    limit = template.limit.get()
    template.limit.set(limit+2)

Template.signupsList.bindI18nNamespace('goingnowhere:volunteers')
Template.signupsList.onCreated () ->
  template = this
  template.limit = new ReactiveVar(4)
  quirks =  template.data?.quirks
  skills =  template.data?.skills

  template.autorun () ->
    limit = template.limit.get()
    if quirks and skills
      share.templateSub(template,"team.ByUserPref",quirks,skills,limit)
    else
      share.templateSub(template,"team")

Template.signupsList.helpers
  LeadListItemGrouped: () -> LeadListItemGroupedContainer,
  'allTeams': () ->
    template = Template.instance()
    limit = template.limit.get()
    filters = template.data?.filters
    query = {}
    query.skills = {$in: filters.skills} if filters?.skills?
    query.quirks = {$in: filters.quirks} if filters?.quirks?
    # teams are ordered using the score that is calculated by considering
    # the priority of the shifts associated with each team
    return share.Team
      .find(query,{sort: {userpref: -1, score: -1}, limit:limit})
  'loadMore' : () ->
    template = Template.instance()
    share.Team.find().count() >= template.limit.get()

Template.signupsList.events
  'click [data-action="loadMoreTeams"]': ( event, template ) ->
    event.preventDefault()
    limit = template.limit.get()
    template.limit.set(limit+2)
