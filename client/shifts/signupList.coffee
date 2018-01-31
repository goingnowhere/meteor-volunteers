import SimpleSchema from 'simpl-schema'

addLocalDutiesCollection = (duties,signups,template,type,filter = {},limit = 10) ->
  duties.find(filter,{limit: limit}).forEach((duty) ->
    duty.type = type
    if ! template.DutiesLocal.findOne(duty._id)
      if ! signups.findOne({userId: Meteor.userId(), shiftId: duty._id})
        # XXX: there must be a better way ... like with an upsert
        template.DutiesLocal.insert(duty)
  )

Template.signupsList.bindI18nNamespace('abate:volunteers')
Template.signupsList.onCreated () ->
  template = this
  template.searchQuery = new ReactiveDict({})
  template.DutiesLocal = new Mongo.Collection(null)
  template.sel = new ReactiveVar({})
  template.isCustumSearch = template.data?.searchQuery?

  if template.isCustumSearch
    template.autorun () ->
      searchQuery = template.data.searchQuery.get()
      template.searchQuery.set('range',searchQuery.range)
      template.searchQuery.set('days',searchQuery.days)
      template.searchQuery.set('period',searchQuery.period)
      template.searchQuery.set('tags',searchQuery.tags)
      template.searchQuery.set('duties',searchQuery.duties)
      template.searchQuery.set('teams',searchQuery.teams)
      template.searchQuery.set('departments',searchQuery.departments)
      template.searchQuery.set('limit',searchQuery.limit)

  template.autorun () ->
    filter = makeFilter(template.searchQuery)
    limit = template.searchQuery.get('limit') || 10
    share.templateSub(template,"TeamShifts",limit)
    share.templateSub(template,"TeamTasks",limit)
    share.templateSub(template,"Lead",limit)
    share.templateSub(template,"ShiftSignups.byUser", Meteor.userId())
    share.templateSub(template,"TaskSignups.byUser", Meteor.userId())
    share.templateSub(template,"LeadSignups.byUser", Meteor.userId())

    if template.subscriptionsReady()
      addLocalDutiesCollection(share.TeamShifts,share.ShiftSignups,template,'shift',filter,limit)
      addLocalDutiesCollection(share.TeamTasks,share.TaskSignups,template,'task',filter,limit)
      addLocalDutiesCollection(share.Lead,share.LeadSignups,template,'lead',filter,limit)
    template.sel.set(filter)

Template.signupsList.helpers
  'allDuties': () -> Template.instance().DutiesLocal.find()

# Template.volunteerShiftsForm.onCreated () ->
#   template = this
#   template.searchQuery = new ReactiveDict({})
#   template.ShiftTaskLocal = new Mongo.Collection(null)
#   template.sel = new ReactiveVar({})
#   template.isCustumSearch = template.data?.searchQuery?
#
#   if template.isCustumSearch
#     template.autorun () ->
#       searchQuery = template.data.searchQuery.get()
#       template.searchQuery.set('range',searchQuery.range)
#       template.searchQuery.set('days',searchQuery.days)
#       template.searchQuery.set('period',searchQuery.period)
#       template.searchQuery.set('tags',searchQuery.tags)
#       template.searchQuery.set('duties',searchQuery.duties)
#       template.searchQuery.set('teams',searchQuery.teams)
#       template.searchQuery.set('departments',searchQuery.departments)
#       template.searchQuery.set('limit',searchQuery.limit)
#
#   template.autorun () ->
#
#     filter = makeFilter(template.searchQuery)
#     limit = template.searchQuery.get('limit') || 10
#     share.templateSub(template,"division")
#     share.templateSub(template,"department")
#     sub = share.templateSub(template,"allDuties", filter, limit)
#
#     if sub.ready()
#       addLocalShiftsCollection(share.TeamShifts,template,'shift',filter,limit)
#       addLocalShiftsCollection(share.TeamTasks,template,'task',filter,limit)
#       addLocalShiftsCollection(share.Lead,template,'lead',filter,limit)
#     template.sel.set(filter)
#
# Template.volunteerShiftsForm.helpers
#   'isCustumSearch': () -> Template.instance().isCustumSearch
#   'searchQuery': () -> Template.instance().searchQuery
#   'loadMore': () ->
#     template = Template.instance()
#     shifts = template.ShiftTaskLocal.find()
#     limit = template.searchQuery.get("limit")
#     shifts.count() <= limit
#   'allShiftsTasks': () ->
#     template = Template.instance()
#     sort = {sort: {isChecked:-1, start: -1, dueDate:-1}}
#     sel = template.sel.get()
#     template.ShiftTaskLocal.find(sel,sort)
#
# Template.volunteerShiftsForm.events
#   'click [data-action="loadMore"]': ( event, template ) ->
#     limit = template.searchQuery.get("limit")
#     template.searchQuery.set("limit",limit+10)
#
# Template.volunteerUserShifts.onCreated () ->
#   template = this
#   template.ShiftTaskLocal = new Mongo.Collection(null)
#
#   template.autorun () ->
#     sub = share.templateSub(template,"allDuties.byUser")
#     if sub.ready()
#       addLocalShiftsCollection(share.TeamShifts,template,'shift')
#       addLocalShiftsCollection(share.TeamTasks,template,'task')
#       addLocalShiftsCollection(share.Lead,template,'lead')
#
# Template.volunteerUserShifts.helpers
#   'allShifts': () ->
#     template = Template.instance()
#     sort = {sort: {start: -1, dueDate:-1}}
#     template.ShiftTaskLocal.find({type: "shift"},sort)
#   'allTasks': () ->
#     template = Template.instance()
#     sort = {sort: {start: -1, dueDate:-1}}
#     template.ShiftTaskLocal.find({type: "task"},sort)
