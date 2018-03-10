import SimpleSchema from 'simpl-schema'

# coll contains shifts unique shifts title
addLocalDutiesCollection = (duties,coll,type,filter,limit) ->
  shifts = duties.find(filter,{limit: limit}).fetch()
  _.chain(shifts).groupBy('title').map((l,title) ->
    duty = { type: type, title: title, parentId: filter.parentId }
    coll.upsert(duty,duty)
  ).value()

Template.signupsListTeam.bindI18nNamespace('abate:volunteers')
Template.signupsListTeam.onCreated () ->
  template = this
  template.team = template.data
  template.limit = new ReactiveVar(10)
  template.DutiesLocal = new Mongo.Collection(null)
  coll = template.DutiesLocal

  sel = {parentId : template.team._id}
  template.autorun () ->
    limit = template.limit.get()
    switch template.team.dutytype
      when "shift"
        share.templateSub(template,"TeamShifts",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(share.TeamShifts,coll,'shift',sel,limit)
      when "task"
        share.templateSub(template,"TeamTasks",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(share.TeamTasks,coll,'task',sel,limit)
      when "project"
        share.templateSub(template,"Projects",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(share.Projects,coll,'project',sel,limit)
      else
        share.templateSub(template,"TeamShifts",sel,limit)
        share.templateSub(template,"TeamTasks",sel,limit)
        share.templateSub(template,"Projects",sel,limit)
        if template.subscriptionsReady()
          addLocalDutiesCollection(share.TeamShifts,coll,'shift',sel,limit)
          addLocalDutiesCollection(share.TeamTasks,coll,'task',sel,limit)
          addLocalDutiesCollection(share.Projects,coll,'project',sel,limit)

Template.signupsListTeam.helpers
  'allShifts': () ->
    template = Template.instance()
    sel = {parentId : template.team._id}
    template.DutiesLocal.find(sel).fetch()
  'loadMore' : () ->
    template = Template.instance()
    sel = {parentId : template.team._id}
    template.DutiesLocal.find(sel).count() >= template.limit.get()

Template.signupsListTeam.events
  'click [data-action="loadMoreShifts"]': ( event, template ) ->
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
    else
      share.templateSub(template,"team",{},limit)

Template.signupsList.helpers
  'allTeams': () ->
    template = Template.instance()
    limit = template.limit.get()
    team = share.Team.find({},{sort: {score: -1}},{limit:limit})
    console.log team.fetch()
    console.log Template.currentData()
    team.dutytype = null
    if Template.currentData()?.dutytype?
      team.dutytype = Template.currentData().dutytype
    return team
  'loadMore' : () ->
    template = Template.instance()
    share.Team.find().count() >= template.limit.get()

Template.signupsList.events
  'click [data-action="loadMoreTeams"]': ( event, template ) ->
    limit = template.limit.get()
    template.limit.set(limit+2)
