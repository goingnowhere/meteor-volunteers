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
    if form then {
      collection: form
      insert:
        label: TAPi18n.__("create_volunteer_profile")
      update:
        label: TAPi18n.__("update_volunteer_profile")
    }
  'data': () -> share.VolunteerForm.findOne({userId: Meteor.userId()})

addLocalLeadsCollection = (template,filter,limit) ->
  orgUnitCollections = [share.Team, share.Department, share.Division]
  share.Lead.find(filter,{limit: limit}).forEach((lead) ->
    team = orgUnitCollections.reduce(((lastUnit, col) =>
      lastUnit || col.findOne(lead.parentId)), null)
    isChecked = if lead.userId == Meteor.userId() then "checked" else null
    sel =
      teamId: team._id
      shiftId: lead._id
    mod =
      type: 'lead'
      teamName: team.name
      parentId: team._id
      title: lead.title
      description: lead.description
      policy: lead.policy
      isChecked: isChecked

    template.ShiftTaskLocal.upsert(sel,{$set: mod})
  )

addLocalShiftsCollection = (collection,template,type,filter = {},limit = 0) ->
  collection.find(filter,{limit: limit}).forEach((job) ->
    team = share.Team.findOne(job.parentId)
    users = []
    signupsSub = share.templateSub(template,"signups.byShift",job._id)
    if signupsSub.ready()
      # share.signupCollections is defined in both/collections/initCollections.coffee
      signupCollection = share.signupCollections[type]
      users = signupCollection.find(
        {shiftId: job._id, status: {$in: ["confirmed"]}}
      ).map((s) -> s.userId)
      signup = signupCollection.findOne({shiftId: job._id, userId: Meteor.userId()})
      department = if team.parentId? then share.Department.findOne(team.parentId)
      division = if department?.parentId? then share.Division.findOne(department.parentId)
      sel =
        teamId: team._id
        shiftId: job._id
      mod =
        type: type
        teamName: team.name
        departmentName: if department?.name? then department.name
        divisionName: if division?.name? then division.name
        parentId: team.parentId
        title: job.title
        description: job.description
        status: if signup then signup.status else null
        canBail: signup? and signup.status != 'bailed'
        policy: job.policy
        tags: team.tags
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
      addLocalLeadsCollection(template,filter,limit)
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
      addLocalShiftsCollection(share.TeamShifts,template,'shift',{},100)
      addLocalShiftsCollection(share.TeamTasks,template,'task',{},100)
      addLocalLeadsCollection(template,{},100)

Template.volunteerUserShifts.helpers
  'allShifts': () ->
    template = Template.instance()
    sort = {sort: {start: -1, dueDate:-1}}
    template.ShiftTaskLocal.find({type: "shift"},sort)
  'allTasks': () ->
    template = Template.instance()
    sort = {sort: {start: -1, dueDate:-1}}
    template.ShiftTaskLocal.find({type: "task"},sort)

Template.volunteersTeamView.onCreated () ->
  template = this
  template.ShiftTaskLocal = new Mongo.Collection(null)
  template.teamId = template.data._id

  template.autorun () ->
    template.sub = share.templateSub(template,"allDuties.byTeam", template.teamId)
    if template.sub.ready()
      addLocalShiftsCollection(share.TeamShifts,template,'shift',{},100)
      addLocalShiftsCollection(share.TeamTasks,template,'task',{},100)
      addLocalLeadsCollection(template,{},100)

Template.volunteersTeamView.helpers
  'team': () ->
    template = Template.instance()
    if template.sub.ready()
      share.Team.findOne(template.teamId)
  'division': () ->
    template = Template.instance()
    if template.sub.ready()
      team = share.Team.findOne(template.teamId)
      department = share.Department.findOne(team.parentId)
      share.Division.findOne(department.parentId)
  'department': () ->
    template = Template.instance()
    if template.sub.ready()
      team = share.Team.findOne(template.teamId)
      share.Department.findOne(team.parentId)
  'allShiftsTasks': () ->
    template = Template.instance()
    template.ShiftTaskLocal.find()
  canEditTeam: () =>
    teamId = Template.instance().data._id
    # console.log(teamId, Roles.userIsInRole(Meteor.userId(), ['manager', teamId], share.eventName))
    Roles.userIsInRole(Meteor.userId(), ['manager', teamId], share.eventName)
  'teamEditEventName': () -> 'teamEdit-'+share.eventName1.get()
