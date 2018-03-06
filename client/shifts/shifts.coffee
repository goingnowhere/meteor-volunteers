Template.dutiesListItem.bindI18nNamespace('abate:volunteers')
Template.dutiesListItem.onCreated () ->
  template = this
  duty = template.data
  share.templateSub(template,"TeamShifts.byDuty", duty._id, Meteor.userId())
  share.templateSub(template,"TeamTasks.byDuty", duty._id, Meteor.userId())
  share.templateSub(template,"Projects.byDuty", duty._id, Meteor.userId())
  share.templateSub(template,"Lead.byDuty", duty._id, Meteor.userId())

dutiesListItemEvents =
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    selectedUser = $(".select-users[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    if type == 'project'
      project = share.Projects.findOne(shiftId)
      AutoFormComponents.ModalShowWithTemplate('projectSignupForm', { signup: doc, project })
    else
      share.meteorCall "#{type}Signups.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.bail", doc

Template.dutiesListItem.events dutiesListItemEvents
Template.dutiesListItemDate.events dutiesListItemEvents

dutiesListItemHelpers =
  'duty': () -> Template.currentData()
  'team': () ->
    duty = Template.currentData()
    if duty.type == "shift" ||  duty.type == "task"
      share.Team.findOne(duty.parentId)
    else
      t = share.Team.findOne(duty.parentId)
      if t then return _.extend(t,{type: "team"}) else
        dt = share.Department.findOne(duty.parentId)
      if dt then return _.extend(dt,{type: "department"}) else
        dv = share.Division.findOne(duty.parentId)
        return _.extend(dv,{type: "division"})
  'signup': () ->
    userId = Meteor.userId()
    duty = Template.currentData()
    if duty.type == "shift"
      return share.ShiftSignups.findOne({userId: userId, shiftId: duty._id})
    else if duty.type == "task"
      return share.TaskSignups.findOne({userId: userId, shiftId: duty._id})
    else if duty.type == "lead"
      return share.LeadSignups.findOne({userId: userId, shiftId: duty._id})
    else if duty.type == "project"
      return share.ProjectSignups.findOne({userId: userId, shiftId: duty._id})

Template.dutiesListItem.helpers dutiesListItemHelpers
Template.dutiesListItemTitle.helpers dutiesListItemHelpers
Template.dutiesListItemDate.helpers dutiesListItemHelpers
Template.dutiesListItemContent.helpers dutiesListItemHelpers

sameDayHelper = {
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")
}

Template.shiftDate.helpers sameDayHelper
Template.shiftDateInline.helpers sameDayHelper

Template.projectDate.helpers
  start: () -> Template.instance().data.start
  end: () -> Template.instance().data.end
  longformDay: (date) => moment(date).format('dddd')

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
  day: (index) =>
    start = AutoForm.getFieldValue('start')
    return moment(start).add(index, 'days').format('MMM Do')
  datesSet: () =>
    start = AutoForm.getFieldValue('start')
    end = AutoForm.getFieldValue('end')
    return start? && end? && moment(start).isBefore(end)
  staffingArray: () =>
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
      .map((_, col) =>
        min: $(col).find('[data-field="min"]').val()
        max: $(col).find('[data-field="max"]').val()
      ).get()
    return values
)

Template.projectSignupForm.bindI18nNamespace('abate:volunteers')
Template.projectSignupForm.onCreated () ->
  template = this
  template.start = new ReactiveVar()
  template.end = new ReactiveVar()

Template.projectSignupForm.helpers
  projectDays: () =>
    project = Template.currentData().project
    current = moment(project.start)
    days = [current]
    while current.isBefore(project.end)
      current = moment(current).add(1, 'days')
      days.push(current)
    Template.instance().days = days
    return days
  formatDay: (day) =>
    day.format('dd Do MMM')
  highlightClass: (index) =>
    start = Template.instance().start.get()
    end = Template.instance().end.get()
    if start == index or end == index
      return "selected"
    if start < index and end > index
      return "in-range"
Template.projectSignupForm.events
  'click [data-action="choose"]': (event, template) =>
    index = $(event.target).data('index')
    if template.start.get()
      if template.start.get() < index
        template.end.set(index)
      else
        template.end.set(template.start.get())
        template.start.set(index)
    else
      template.start.set(index)
  'click [data-action="apply"]': (event, template) =>
    startIndex = template.start.get()
    endIndex = template.end.get()
    if startIndex? and endIndex?
      start = template.days[startIndex].toDate()
      end = template.days[endIndex].toDate()
      signup = _.extend(template.data.signup, { start, end })
      share.meteorCall "projectSignups.insert", signup
      Modal.hide()
