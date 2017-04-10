import SimpleSchema from 'simpl-schema'

Template.addVolunteerForm.onCreated () ->
  template = this
  template.autorun () ->
    Meteor.subscribe('FormBuilder.dynamicForms', () ->
      share.extendVolunteerForm() )

Template.addVolunteerForm.helpers
  'form': () -> { collection: share.form.get() }

makeFilter = (searchQuery) ->
  sel = []
  rangeList = searchQuery.get('range')
  if rangeList.length > 0
    range = _.map(rangeList,(d) -> moment(d, 'YYYY-MM-DD'))
    range = moment.range(rangeList)
    sel.push
      $and: [
        {start: { $gte: range.start.startOf('day').toDate() }},
        {start: { $lt: range.end.endOf('day').toDate() }}
      ]
  # console.log "range",sel

  daysList = searchQuery.get('range')
  # if daysList.length > 0
  #   range = _.map(rangeList,(d) -> moment(d, 'YYYY-MM-DD'))
  #   range = moment.range(rangeList)
  #   sel.push
  #     $and: [
  #       {start: { $gte: range.start.toDate() }},
  #       {start: { $lt: range.end.toDate() }}
  #     ]
  # console.log "days",sel

  periodList = searchQuery.get('period')
  if periodList && periodList.length > 0
    periods = share.periods.get()
    for p in periodList
      sel.push
        $and: [
          {startTime: { $gte: periods[p].start }},
          {startTime: { $lt: periods[p].end }}
        ]

  tags = searchQuery.get('tags')
  if tags.length > 0 then sel.push {tags: { $in: tags }}

  # types = searchQuery.get('types')
  # console.log "AAAAAAA",types
  # if types.length > 0
  #   sel.push {type: { $in: types }}
  # else
  #   types = ['shift','task','lead']
  #   sel.push {type: { $in: types }}

  areas = searchQuery.get('areas')

  return if sel.length > 0 then {"$or": sel} else {}

addLocalShiftsCollection = (collection,template,type) ->
  filter = makeFilter(template.searchQuery)
  limit = template.searchQuery.get('limit')
  collection.find(filter,{limit: limit}).forEach((shift) ->
    team = share.Team.findOne(shift.teamId)
    # We subscribe only to shifts belonging to this user
    sel = {shiftId: shift._id, type: type}
    isChecked = if share.Shifts.findOne(sel) then "checked" else null
    sel =
      teamId: team._id
      shiftId: shift._id
    mod =
      type: type
      teamName: team.name
      # areaIds: if team.parents then team.parents else []
      title: shift.title
      description: shift.description
      isChecked: isChecked
      tags: team.tags
      areas: team.areas
      rnd: Random.id()

    if type == 'shift'
      _.extend(mod,
        start: shift.start
        end: shift.end
        startTime: shift.startTime
        endTime: shift.endTime)
    if type == 'task' then _.extend(mod, {dueDate : shift.dueDate })
    if type == 'lead' then _.extend(mod, {role : shift.role })
    template.ShiftTaskLocal.upsert(sel,{$set: mod})
  )

Template.volunteerShiftsForm.onCreated () ->
  template = this
  template.searchQuery = new ReactiveDict()
  template.sel = new ReactiveVar({})
  template.ShiftTaskLocal = new Mongo.Collection(null)

  template.subscribe('Volunteers.shifts')

  template.searchQuery.set('range',[])
  template.searchQuery.set('days',[])
  template.searchQuery.set('period',[])
  template.searchQuery.set('tags',[])
  template.searchQuery.set('types',[])
  template.searchQuery.set('areas',[])
  template.searchQuery.set('limit',10)

  template.autorun () ->
    filter = makeFilter(template.searchQuery)
    limit = template.searchQuery.get('limit')
    sub = template.subscribe('Volunteers.allDuties', filter, limit)

    # each type should be trigger only is template.searchQuery.get('type')
    if sub.ready()
      addLocalShiftsCollection(share.TeamShifts,template,'shift')
      addLocalShiftsCollection(share.TeamTasks,template,'task')
      addLocalShiftsCollection(share.Lead,template,'lead')
    template.sel.set(filter)

Template.volunteerShiftsForm.helpers
  'searchQuery': () -> Template.instance().searchQuery
  'loadNoMore': () ->
    # template = Template.instance()
    # shifts = template.ShiftTaskLocal.find()
    # limit = template.searchQuery.get("limit")
    # shifts.count() < limit
    false
  'allShiftsTasks': () ->
    template = Template.instance()
    sort = {sort: {isCheckbox:1, start: 1, dueDate:1}}
    sel = template.sel.get()
    Template.instance().ShiftTaskLocal.find(sel,sort)

Template.volunteerShiftsForm.events
  'click [data-action="loadMore"]': ( event, template ) ->
    limit = template.searchQuery.get("limit")
    template.searchQuery.set("limit",limit+10)
  'change [data-type="toggleShift"]': ( event, template ) ->
    checked = event.target.checked
    shiftId = $(event.target).data('shiftid')
    teamId = $(event.target).data('teamid')
    userId = Meteor.userId()
    sel = {teamId:teamId,shiftId:shiftId}
    op = if checked == false then "pull" else "push"
    Meteor.call "Volunteers.shift.upsert", sel,op,userId

# Template.volunteerList.helpers
#   "isVolunteer": () ->
#     VolunteerForm.find({userId: Meteor.userId()}).count() > 0
#   "hasLead": () ->
#     roles = AppRoles.find({withShifts:false}).map((e) -> e._id)
#     crew = VolunteerCrew.find({userId:Meteor.userId(),roleId:{$in: roles}})
#     crew.count() > 0
#   "hasShift": () ->
#     roles = AppRoles.find({withShifts:true}).map((e) -> e._id)
#     crew = VolunteerCrew.find({userId:Meteor.userId(),roleId:{$in: roles}})
#     crew.count() > 0
#   'VolunteerCrewUserTableSettings': () ->
#     roles = AppRoles.find({withShifts:false}).map((e) -> e._id)
#     collection: VolunteerCrew.find({userId:Meteor.userId(),roleId:{$in: roles}})
#     # currentPage: Template.instance().currentPage
#     class: "table table-bordered table-hover"
#     showNavigation: 'never'
#     rowsPerPage: 20
#     showRowCount: false
#     showFilter: false
#     fields: [
#       {
#         key: 'roleId',
#         label: (() -> TAPi18n.__("role")),
#         fn: (val,row,label) ->
#           TAPi18n.__(AppRoles.findOne(val).name)},
#       {
#         key: 'areaId',
#         label: (() -> TAPi18n.__("area")),
#         fn: (val,row,label) ->
#           TAPi18n.__(Areas.findOne(val).name)},
#     ]
#   'VolunteerShiftUserTableSettings': () ->
#     crews = VolunteerCrew.find({userId: Meteor.userId()}).map((res) -> res._id)
#     collection: VolunteerShift.find({crewId: {$in: crews}})
#     # currentPage: Template.instance().currentPage
#     class: "table table-bordered table-hover"
#     showNavigation: 'never'
#     rowsPerPage: 20
#     showRowCount: false
#     showFilter: false
#     fields: [
#       {
#         key: 'role',
#         label: (() -> TAPi18n.__("role")),
#         fn: (val,row,label) ->
#           roleId = VolunteerCrew.findOne(row.crewId).roleId
#           TAPi18n.__(AppRoles.findOne(roleId).name)},
#       {
#         key: 'area',
#         label: (() -> TAPi18n.__("area")),
#         fn: (val,row,label) ->
#           areaId = VolunteerCrew.findOne(row.crewId).areaId
#           TAPi18n.__(Areas.findOne(areaId).name)},
#       {
#         key: 'teamId',
#         label: (() -> TAPi18n.__("team")),
#         fn: (val,row,label) ->
#           if val then TAPi18n.__(Team.findOne(val).name)
#         cellClass: "volunteer-task-td"},
#       { key: 'start', label: (() -> TAPi18n.__("start"))},
#       { key: 'end', label: (() -> TAPi18n.__("end"))},
#       {
#         key: 'leadId',
#         label: (() -> TAPi18n.__("leads")),
#         fn: (val,row,label) ->
#           areaId = VolunteerCrew.findOne(row.crewId).areaId
#           _.map(getAreaLeads(areaId),(l) ->getUserName(l.userId))
#       },
#     ]
#
# Template.publicVolunteerCal.onCreated () ->
#   area = Areas.findOne()
#   Session.set('currentAreaTab',{areaId:area._id})
#
# Template.publicVolunteerCal.helpers
#   'currentAreaTab': () -> Session.get('currentAreaTab')
#   'areas': () -> Areas.find().fetch()
#   'options': () ->
#     id: "publicVolunteerAreaCal"
#     schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source'
#     scrollTime: '06:00'
#     slotDuration: "00:15"
#     aspectRatio: 1.5
#     now: Settings.findOne().dday
#     locale: Meteor.user().profile.language
#     defaultView: 'timelineDay'
#     views:
#       timelineThreeDays:
#         type: 'timeline'
#         duration: { days: 2 }
#     header:
#       right: 'timelineTwoDays, timelineDay, prev,next'
#     resourceLabelText: TAPi18n.__ "team"
#     resourceAreaWidth: "20%"
#     resources: (callback) ->
#       areaId = Session.get('currentAreaTab').areaId
#       businessHours = (team) ->
#         _.map(team.shifts, (shift) -> {
#           start: shift.start,
#           end: shift.end,
#           dow: [0, 1, 2, 3, 4, 5, 6]
#         })
#       resources = Team.find({areaId:areaId}).map((team) ->
#         id: team._id
#         resourceId: team._id
#         title: team.name
#         businessHours: businessHours(team))
#       callback(resources)
#     events: (start, end, tz, callback) ->
#       areaId = Session.get('currentAreaTab').areaId
#       events = VolunteerShift.find({areaId:areaId}).map((res) ->
#         title: getUserName(VolunteerCrew.findOne(res.crewId).userId)
#         resourceId: res.teamId # this is the fullCalendar resourceId / Team
#         crewId: res.crewId
#         userId: res.userId
#         eventId: res._id
#         start: moment(res.start, "DD-MM-YYYY H:mm")
#         end: moment(res.end, "DD-MM-YYYY H:mm"))
#       callback(events)
#
# Template.publicVolunteerCal.events
#   'click [data-action="switchTab"]': (event,template) ->
#     areaId = $(event.target).data('id')
#     Session.set('currentAreaTab',{areaId:areaId})
#     $('#publicVolunteerAreaCal').fullCalendar('refetchEvents')
#     $('#publicVolunteerAreaCal').fullCalendar('refetchResources')
#
# AutoForm.hooks
#   insertVolunteerForm:
#     onSuccess: () ->
#       sAlert.success(TAPi18n.__('alert_success_update_volunteer_form'))
#       Session.set("currentTab",{template: 'volunteerList'})
#   updateVolunteerForm:
#     onSuccess: () ->
#       sAlert.success(TAPi18n.__('alert_success_update_volunteer_form'))
#       Session.set("currentTab",{ template: 'volunteerList'})
