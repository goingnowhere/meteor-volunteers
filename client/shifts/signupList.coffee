import SimpleSchema from 'simpl-schema'

ShiftTitles = new Mongo.Collection(null)

# coll contains shifts unique shifts title
addLocalDutiesCollection = (duties,type,filter,limit) ->
  ShiftTitles.remove({type, parentId: filter.parentId})
  shifts = duties.find(filter,{limit: limit}).fetch()
  _.chain(shifts).groupBy('title').map((l,title) ->
    duty = { type: type, title: title, parentId: filter.parentId }
    ShiftTitles.upsert(duty,duty)
  ).value()

Template.signupsListTeam.bindI18nNamespace('abate:volunteers')
Template.signupsListTeam.onCreated () ->
  template = this
  template.limit = new ReactiveVar(10)
  {team, dutyType} = template.data

  template.autorun () ->
    sel = {parentId : team._id}
    limit = template.limit.get()
    {filters} = Template.currentData()
    if filters?.priorities?
      sel.priority = {$in: filters.priorities}
    if dutyType?
      switch dutyType
        when "shift"
          share.templateSub(template,"TeamShifts",sel,limit)
          if template.subscriptionsReady()
            addLocalDutiesCollection(share.TeamShifts,'shift',sel,limit)
        when "task"
          share.templateSub(template,"TeamTasks",sel,limit)
          if template.subscriptionsReady()
            addLocalDutiesCollection(share.TeamTasks,'task',sel,limit)
        when "project"
          share.templateSub(template,"Projects",sel,limit)
          if template.subscriptionsReady()
            addLocalDutiesCollection(share.Projects,'project',sel,limit)
    else
      share.templateSub(template,"TeamShifts",sel,limit)
      share.templateSub(template,"TeamTasks",sel,limit)
      share.templateSub(template,"Projects",sel,limit)
      if template.subscriptionsReady()
        addLocalDutiesCollection(share.TeamShifts,'shift',sel,limit)
        addLocalDutiesCollection(share.TeamTasks,'task',sel,limit)
        addLocalDutiesCollection(share.Projects,'project',sel,limit)

Template.signupsListTeam.helpers
  'allShifts': () ->
    template = Template.instance()
    {team, dutyType} = template.data
    sel = {parentId : team._id}
    if dutyType?
      sel.type = dutyType
    if template.subscriptionsReady()
      ShiftTitles.find(sel).fetch()
    else []
  'loadMore' : () ->
    template = Template.instance()
    sel = {parentId : template.data.team._id}
    if template.data.dutyType?
      sel.type = template.data.dutyType
    ShiftTitles.find(sel).count() >= template.limit.get()

Template.signupsListTeam.events
  'click [data-action="loadMoreShifts"]': ( event, template ) ->
    event.preventDefault()
    limit = template.limit.get()
    template.limit.set(limit+2)

Template.signupsList.bindI18nNamespace('abate:volunteers')
Template.signupsList.onCreated () ->
  template = this
  template.limit = new ReactiveVar(10)
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
