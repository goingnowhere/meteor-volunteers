import moment from 'moment'

getDuty = (type,title) ->
  sel = {title: title}
  switch type
    when "shift" then share.TeamShifts.findOne(sel)
    when "task" then share.TeamTasks.findOne(sel)
    when "project" then share.Projects.findOne(sel)
    when "lead" then share.Lead.findOne(sel)

getTeam = (type,parentId) ->
  switch type
    when "shift" then share.Team.findOne(parentId)
    when "task" then share.Team.findOne(parentId)
    else
      t = share.Team.findOne(parentId)
      if t then return _.extend(t,{type: "team"})
      else
        dt = share.Department.findOne(parentId)
        if dt then return _.extend(dt,{type: "department"})
        else
          dv = share.Division.findOne(parentId)
          return _.extend(dv,{type: "division"})

# client side collection
DatesLocal = new Mongo.Collection(null)

# DatesLocal contains all shifts (dates) related to a particular title
# and parentId
addLocalDatesCollection = (duties,type,filter) ->
  duties.find(filter).forEach((duty) ->
    duty.type = type
    duty.team = getTeam(type,duty.parentId)
    duty.signup = (
      sel = {userId: Meteor.userId(), shiftId: duty._id}
      switch duty.type
        when "shift" then share.ShiftSignups.findOne(sel)
        when "task" then share.TaskSignups.findOne(sel)
        when "project" then share.ProjectSignups.findOne(sel)
      )
    DatesLocal.upsert(duty._id,duty)
  )

Template.leadListItemGroupped.bindI18nNamespace('abate:volunteers')
Template.leadListItemGroupped.onCreated () ->
  template = this
  team = template.data
  template.limit = new ReactiveVar(2)
  userId = Meteor.userId()

  sel = {parentId: team._id}
  template.autorun () ->
    limit = template.limit.get()
    share.templateSub(template,"Lead",sel,limit)
    share.templateSub(template,"LeadSignups.byUser", userId)

Template.leadListItemGroupped.helpers
  'loadMore': () ->
    template = Template.instance()
    team = Template.currentData()
    if team
      sel = {parentId: team._id}
      share.Lead.find(sel).count() >= template.limit.get()
  'allLeads': () ->
    template = Template.instance()
    team = Template.currentData()
    userId = Meteor.userId()
    if team
      sel = {parentId: team._id}
      leads = share.Lead.find(sel).map((lead) ->
        lead.team = getTeam('lead',lead.parentId)
        sel = {userId: userId, shiftId: lead._id}
        lead.signup = share.LeadSignups.findOne(sel)
        lead.type = 'lead'
        return lead
      )
      # _.filter(leads,(lead) -> ! lead.signup.status? )
      leads

Template.leadListItemGroupped.events
  'click [data-action="loadMoreLeads"]': ( event, template ) ->
    limit = template.limit.get()
    template.limit.set(limit+2)

Template.leadListItemGroupped.events
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    userId = Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.insert", doc

Template.signupModal.onCreated () ->
  template = this
  {parentId, title, dutyType} = template.data
  userId = Meteor.userId()

  sel = {title, parentId}
  template.autorun () ->
    switch dutyType
      when "shift"
        share.templateSub(template,"TeamShifts",sel)
        share.templateSub(template,"ShiftSignups.byUser", userId)
        if template.subscriptionsReady()
          addLocalDatesCollection(share.TeamShifts,'shift',sel)
      when "task"
        share.templateSub(template,"TeamTasks",sel)
        share.templateSub(template,"TaskSignups.byUser", userId)
        if template.subscriptionsReady()
          addLocalDatesCollection(share.TeamTasks,'task',sel)
      when "project"
        share.templateSub(template,"Projects",sel)
        share.templateSub(template,"ProjectSignups.byUser", userId)
        if template.subscriptionsReady()
          addLocalDatesCollection(share.Projects,'project',sel)
Template.signupModal.helpers
  allDates: () ->
    template = Template.instance()
    {title} = template.data
    sel = {title: title}
    DatesLocal.find(sel, {sort: { "start": -1 }})

Template.dutiesListItemGroupped.bindI18nNamespace('abate:volunteers')
Template.dutiesListItemGroupped.helpers
  projectDisplay: (duty) ->
    _.extend({}, duty.shift, {type: duty.type, team: duty.team})
  shiftLengths: (shift) ->
    {start, end} = shift
    moment(end).diff(start, 'hours')

Template.dutiesListItemGroupped.events
  'click [data-action="chooseShifts"]': ( event, template ) ->
    parentId = $(event.target).data('parent-id')
    groupTitle = $(event.target).data('group-title')
    dutyType = $(event.target).data('duty-type')
    Modal.show("signupModal", {
      title: groupTitle,
      parentId,
      dutyType,
    })

Template.dutiesListItemDate.bindI18nNamespace('abate:volunteers')
Template.dutiesListItemDate.helpers
  # TODO update when upgrading to mongodb > 3.2
  gaps: () ->
    {min, signedUp = 0} = Template.currentData()
    Math.max(0, min - signedUp)
  spotsleft: () ->
    {max, signedUp = 0} = Template.currentData()
    Math.max(0, max - signedUp)

Template.dutiesListItemDate.events
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    userId = Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    if type == 'project'
      project = share.Projects.findOne(shiftId)
      AutoFormComponents.ModalShowWithTemplate('projectSignupForm',
        { signup: doc, project }, project.title, 'lg')
    else
      share.meteorCall "#{type}Signups.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    userId = Meteor.userId()
    share.meteorCall "#{type}Signups.bail", {parentId, shiftId, userId}

sameDayHelper = {
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")
}

Template.shiftDate.helpers sameDayHelper
Template.shiftDateInline.helpers sameDayHelper

Template.projectDate.helpers
  start: () -> Template.instance().data.start
  end: () -> Template.instance().data.end
  longformDay: (date) -> moment(date).format('dddd')

Template.addShift.bindI18nNamespace('abate:volunteers')
Template.addShift.helpers
  'form': () -> {
    collection: share.TeamShifts,
    update: {label: i18n.__("abate:volunteers","update_shift") },
    insert: {label: i18n.__("abate:volunteers","new_shift") }
  }
  'data': () -> parentId: Template.currentData().team?._id

Template.addTask.bindI18nNamespace('abate:volunteers')
Template.addTask.helpers
  'form': () -> { collection: share.TeamTasks }
  'data': () ->
    parentId: Template.currentData().team?._id

Template.addProject.bindI18nNamespace('abate:volunteers')
Template.addProject.helpers
  'form': () -> { collection: share.Projects }
  'data': () ->
    parentId: Template.currentData().team?._id

AutoForm.addHooks ['InsertTeamShiftsFormId','UpdateTeamShiftsFormId'],
  onSuccess: (formType, result) ->
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})

Template.projectStaffingInput.bindI18nNamespace('abate:volunteers')
Template.projectStaffingInput.helpers
  day: (index) ->
    start = AutoForm.getFieldValue('start')
    return moment(start).add(index, 'days').format('MMM Do')
  datesSet: () ->
    start = AutoForm.getFieldValue('start')
    end = AutoForm.getFieldValue('end')
    return start? && end? && moment(start).isBefore(end)
  staffingArray: () ->
    start = AutoForm.getFieldValue('start')
    end = AutoForm.getFieldValue('end')
    if start? && end?
      staffing = AutoForm.getFieldValue('staffing') || []
      days = moment(end).diff(moment(start), 'days') + 1
      if days > staffing.length
        return staffing.concat(Array(days - staffing.length).fill({}))
      else
        return staffing.slice(0, days)
AutoForm.addInputType("projectStaffing",
  template: 'projectStaffingInput'
  valueOut: () ->
    values = this.find('[data-index]')
      .map((_, col) ->
        min: $(col).find('[data-field="min"]').val()
        max: $(col).find('[data-field="max"]').val()
      ).get()
    return values
)

Template.projectSignupForm.bindI18nNamespace('abate:volunteers')
Template.projectSignupForm.onCreated () ->
  template = this
  project = template.data.project
  share.templateSub(template,"Projects.byDuty",project._id)
  template.allDays = new ReactiveVar()
  template.confirmed = new ReactiveVar()
  share.meteorCall("getProjectStaffing", project._id, (err, confirmed) => template.confirmed.set(confirmed))
  template.autorun () ->
    if template.subscriptionsReady()
      projectLength = moment(project.end).diff(moment(project.start), 'days')
      template.allDays.set(moment(project.start).add(num, 'days') for num in [0..projectLength])
Template.projectSignupForm.helpers
  allDays: () ->
    Template.instance().allDays.get()
      ?.map((day) => {label: day.format('MMM Do'), value: day.format('YYYY-MM-DD')})
  endDays: () ->
    start = AutoForm.getFieldValue('start')
    days = Template.instance().allDays.get()
      ?.filter((day) -> day.isSameOrAfter(moment(start)))
      ?.map((day) -> {label: day.format('MMM Do'), value: day.format('YYYY-MM-DD')})
  collection: () -> share.ProjectSignups
  methodName: () -> "#{share.ProjectSignups._name}.insert"
  updateLabel: () ->
    if Template.currentData().project.policy == "public"
      i18n.__("abate:volunteers",".join")
    else
      i18n.__("abate:volunteers",".apply")
  confirmed: () => Template.instance().confirmed.get()

AutoForm.addHooks([
  'projectSignupsInsert',
],
  onSuccess: () ->
    Modal.hide()
)
