import SimpleSchema from 'simpl-schema'

addLocalDutiesCollection = (duties,signups,template,type,filter = {},limit = 10) ->
  duties.find(filter,{limit: limit}).forEach((duty) ->
    duty.type = type
    if ! template.DutiesLocal.findOne(duty._id)
      if ! signups.findOne({userId: Meteor.userId(), shiftId: duty._id, status: 'confirmed'})
        # XXX: there must be a better way ... like with an upsert
        template.DutiesLocal.insert(duty)
  )

makeFilter = (searchQuery) ->
  sel = []
  teams = searchQuery.get('teams')
  if teams?.length > 0 then sel.push {parentId: { $in: teams }}

  departments = searchQuery.get('departments')
  if departments?.length > 0 then sel.push {parentId: { $in: departments }}

  return sel

MakeShiftFilter = (searchQuery) ->
  sel = makeFilter(searchQuery)

  # TODO: add these filters back.
  # rangeList = searchQuery.get('range')
  # if rangeList?.length > 0
  #   range = _.map(rangeList,(d) -> moment(d, 'YYYY-MM-DD'))
  #   range = moment.range(rangeList)
  #   sel.push
  #     $and: [
  #       {start: { $gte: range.start.startOf('day').toDate() }},
  #       {start: { $lt: range.end.endOf('day').toDate() }}
  #     ]
  # console.log "range",sel

  # daysList = searchQuery.get('range')
  # if daysList.length > 0
  #   range = _.map(rangeList,(d) -> moment(d, 'YYYY-MM-DD'))
  #   range = moment.range(rangeList)
  #   sel.push
  #     $and: [
  #       {start: { $gte: range.start.toDate() }},
  #       {start: { $lt: range.end.toDate() }}
  #     ]
  # console.log "days",sel

  # periodList = searchQuery.get('period')
  # if periodList?.length > 0
  #   periods = share.periods.get()
  #   for p in periodList
  #     sel.push
  #       $and: [
  #         {startTime: { $gte: periods[p].start }},
  #         {startTime: { $lt: periods[p].end }}
  #       ]

  return if sel.length > 0 then {"$and": sel} else {}

MakeProjectFilter = (searchQuery) ->
  sel = makeFilter(searchQuery)
  return if sel.length > 0 then {"$and": sel} else {}

MakeLeadFilter = (searchQuery) ->
  sel = makeFilter(searchQuery)
  return if sel.length > 0 then {"$and": sel} else {}

MakeDutyFilter = (searchQuery) ->
  sel = makeFilter(searchQuery)
  duties = searchQuery.get('duties')
  if duties?.length > 0 then sel.push {type: { "$in": duties }}
  return if sel.length > 0 then {"$and": sel} else {}

Template.signupsList.bindI18nNamespace('abate:volunteers')
Template.signupsList.onCreated () ->
  template = this
  userId = Meteor.userId()
  template.searchQuery = new ReactiveDict({})
  template.DutiesLocal = new Mongo.Collection(null)
  template.sel = new ReactiveVar({})
  template.isCustumSearch = template.data?.searchQuery?

  if template.isCustumSearch
    template.autorun () ->
      searchQuery = template.data.searchQuery.get()
      # template.searchQuery.set('range',searchQuery.range)
      # template.searchQuery.set('days',searchQuery.days)
      # template.searchQuery.set('period',searchQuery.period)
      template.searchQuery.set('duties',searchQuery.duties)
      template.searchQuery.set('teams',searchQuery.teams)
      template.searchQuery.set('departments',searchQuery.departments)
      template.searchQuery.set('limit',searchQuery.limit)

  template.autorun () -> (
    shiftFilter = MakeShiftFilter(template.searchQuery)
    projectFilter = MakeProjectFilter(template.searchQuery)
    leadFilter = MakeLeadFilter(template.searchQuery)
    limit = template.searchQuery.get('limit') || 10
    share.templateSub(template,"TeamShifts",shiftFilter,limit)
    share.templateSub(template,"TeamTasks",shiftFilter,limit)
    share.templateSub(template,"Projects",projectFilter,limit)
    share.templateSub(template,"Lead",leadFilter,limit)
    share.templateSub(template,"ShiftSignups.byUser", userId)
    share.templateSub(template,"TaskSignups.byUser", userId)
    share.templateSub(template,"ProjectSignups.byUser", userId)
    share.templateSub(template,"LeadSignups.byUser", userId)

    if template.subscriptionsReady()
      addLocalDutiesCollection(share.TeamShifts,share.ShiftSignups,template,'shift',shiftFilter,limit)
      addLocalDutiesCollection(share.TeamTasks,share.TaskSignups,template,'task',shiftFilter,limit)
      addLocalDutiesCollection(share.Projects,share.ProjectSignups,template,'project',projectFilter,limit)
      addLocalDutiesCollection(share.Lead,share.LeadSignups,template,'lead',leadFilter,limit)

    template.sel.set(MakeDutyFilter(template.searchQuery))
  )

Template.signupsList.helpers
  'allDuties': () ->
    filter = Template.instance().sel.get()
    Template.instance().DutiesLocal.find(filter)
