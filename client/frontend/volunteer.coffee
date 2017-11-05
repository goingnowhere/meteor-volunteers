import SimpleSchema from 'simpl-schema'

Template.addVolunteerForm.onCreated () ->
  template = this
  template.subscribe('FormBuilder.dynamicForms')
  share.templateSub(template,"volunteerForm")

# XXX this should be modified to allow the admin to edit the data of any
# user and not only display Meteor.userId() / the current user
Template.addVolunteerForm.helpers
  'form': () ->
    form = share.form.get()
    if form then { collection: form }
  'data': () -> share.VolunteerForm.findOne({userId: Meteor.userId()})

addLocalLeadsCollection = (template,filter,limit) ->
  share.Lead.find(filter,{limit: limit}).forEach((lead) ->
    if lead.position == 'team'
      team = share.Team.findOne(lead.parentId)
    else if lead.position == 'department'
      team = share.Department.findOne(lead.parentId)
    else if lead.position == 'division'
      team = share.Division.findOne(lead.parentId)
    isChecked = if lead.userId == Meteor.userId() then "checked" else null
    sel =
      teamId: team._id
      shiftId: lead._id
    mod =
      type: 'lead'
      teamName: team.name
      parentId: team.parentId
      title: lead.role
      role: lead.role
      description: shift.description
      isChecked: isChecked
      rnd: Random.id()

    template.ShiftTaskLocal.upsert(sel,{$set: mod})
  )

addLocalShiftsCollection = (collection,template,type,filter = {},limit = 0) ->
  collection.find(filter,{limit: limit}).forEach((job) ->
    team = share.Team.findOne(job.parentId)
    users = []
    shiftSignupsSub = share.templateSub(template,"shiftSignups.byShift",job._id)
    taskSignupsSub = share.templateSub(template,"taskSignups.byShift",job._id)
    if shiftSignupsSub.ready() and taskSignupsSub.ready()
      # share.signupCollections is defined in both/collections/initCollections.coffee
      signupCollection = share.signupCollections[type]
      users = signupCollection.find(
        {shiftId: job._id, status: {$in: ["confirmed"]}}
      ).map((s) -> s.userId)
      signup = signupCollection.findOne({shiftId: job._id, userId: Meteor.userId()})
      sel =
        teamId: team._id
        shiftId: job._id
      mod =
        type: type
        teamName: team.name
        parentId: team.parentId
        title: job.title
        description: job.description
        status: if signup then signup.status else null
        canBail: signup? and signup.status != 'bailed'
        policy: job.policy
        tags: team.tags
        rnd: Random.id()
        users: users
      if type == 'shift'
        _.extend(mod,
          start: job.start
          end: job.end
          startTime: job.startTime
          endTime: job.endTime)
      if type == 'task'
        _.extend(mod,
          dueDate : job.dueDate
          estimatedTime: job.estimatedTime)
      template.ShiftTaskLocal.upsert(sel,{$set: mod})
    )

Template.volunteerShiftsForm.onCreated () ->
  template = this
  template.searchQuery = new ReactiveDict()
  template.ShiftTaskLocal = new Mongo.Collection(null)
  template.sel = new ReactiveVar({})

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
    share.templateSub(template,"division")
    share.templateSub(template,"department")
    sub = share.templateSub(template,"allDuties", filter, limit)

    if sub.ready()
      addLocalShiftsCollection(share.TeamShifts,template,'shift',filter,limit)
      addLocalShiftsCollection(share.TeamTasks,template,'task',filter,limit)
      # addLocalLeadsCollection(template,filter,limit)
    template.sel.set(filter)

Template.volunteerShiftsForm.helpers
  'searchQuery': () -> Template.instance().searchQuery
  'loadMore': () ->
    template = Template.instance()
    shifts = template.ShiftTaskLocal.find()
    limit = template.searchQuery.get("limit")
    shifts.count() <= limit
  'allShiftsTasks': () ->
    template = Template.instance()
    sort = {sort: {isChecked:-1, start: -1, dueDate:-1}}
    sel = template.sel.get()
    template.ShiftTaskLocal.find(sel,sort)

Template.volunteerShiftsForm.events
  'click [data-action="loadMore"]': ( event, template ) ->
    limit = template.searchQuery.get("limit")
    template.searchQuery.set("limit",limit+10)

Template.volunteerUserShifts.onCreated () ->
  template = this
  template.ShiftTaskLocal = new Mongo.Collection(null)

  template.autorun () ->
    sub = share.templateSub(template,"allDuties.byUser")

    if sub.ready()
      addLocalShiftsCollection(share.TeamShifts,template,'shift',{},10)
      addLocalShiftsCollection(share.TeamTasks,template,'task',{},10)
      # addLocalLeadsCollection(template,filter,limit)

Template.volunteerUserShifts.helpers
  'allShifts': () ->
    template = Template.instance()
    sort = {sort: {start: -1, dueDate:-1}}
    template.ShiftTaskLocal.find({type: "shift"},sort)
  'allTasks': () ->
    template = Template.instance()
    sort = {sort: {start: -1, dueDate:-1}}
    template.ShiftTaskLocal.find({type: "task"},sort)

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
