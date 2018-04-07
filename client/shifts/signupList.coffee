import SimpleSchema from 'simpl-schema'

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
      shift,
      team,
    }
    ShiftTitles.insert(duty)
  ).value()

Template.signupsListTeam.bindI18nNamespace('abate:volunteers')
Template.signupsListTeam.onCreated () ->
  template = this
  {team, dutyType = ''} = template.data

  template.autorun () ->
    sel = {parentId : team._id}
    # Only need one to get details of the shift
    limit = 1
    {filters} = Template.currentData()
    if filters?.priorities?
      sel.priority = {$in: filters.priorities}
    switch dutyType
      when "shift"
        share.templateSub(template,"TeamShifts",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.TeamShifts,'shift',sel,limit)
      when "task"
        share.templateSub(template,"TeamTasks",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.TeamTasks,'task',sel,limit)
      when "project"
        share.templateSub(template,"Projects",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.Projects,'project',sel,limit)
      else
        share.templateSub(template,"TeamShifts",sel,limit)
        share.templateSub(template,"TeamTasks",sel,limit)
        share.templateSub(template,"Projects",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(team,share.TeamShifts,'shift',sel,limit)
          addLocalDutiesCollection(team,share.TeamTasks,'task',sel,limit)
          addLocalDutiesCollection(team,share.Projects,'project',sel,limit)

Template.signupsListTeam.helpers
  'allShifts': () ->
    template = Template.instance()
    {team, dutyType = ''} = template.data
    sel = {parentId : team._id}
    if dutyType in ['shift', 'lead', 'project']
      sel.type = dutyType
    if template.subscriptionsReady()
      ShiftTitles.find(sel).fetch()
    else []

Template.signupsListTeam.events
  'click [data-action="loadMoreShifts"]': ( event, template ) ->
    event.preventDefault()
    limit = template.limit.get()
    template.limit.set(limit+2)

Template.signupsList.bindI18nNamespace('abate:volunteers')
Template.signupsList.onCreated () ->
  template = this
  # Move limit to unreasonably high as limiting lead to weird behaviour
  # e.g. only one team appearing as there weren't any shifts to show for most teams with filtering
  template.limit = new ReactiveVar(50)
  quirks =  template.data?.quirks
  skills =  template.data?.skills

  template.autorun () ->
    limit = template.limit.get()
    if quirks and skills
      share.templateSub(template,"team.ByUserPref",quirks,skills,limit)
    # else
      # share.templateSub(template,"team",limit)

Template.signupsList.helpers
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
