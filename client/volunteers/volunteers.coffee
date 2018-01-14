
events =
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    parentId = $(event.target).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "shiftSignups.bail", doc

# this template is called with a shiftSignups
Template.shiftsUserRowView.onCreated () ->
  template = this
  template.shiftSignup = template.data
  share.templateSub(template,"ShiftSignups.byUser", template.shiftSignup.userId)

Template.shiftsUserRowView.helpers
  'team': () -> share.Team.findOne(Template.instance().shiftSignup.parentId)
  'shift': () -> share.TeamShifts.findOne(Template.instance().shiftSignup.shiftId)
  'signup': () -> share.ShiftSignups.findOne(Template.instance().shiftSignup._id)
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")

Template.shiftsUserRowView.events events

# this template is called with a taskSignups
Template.tasksUserRowView.onCreated () ->
  template = this
  template.taskSignup = template.data
  sub = share.templateSub(template,"TasksSignups.byUser", template.taskSignup.userId)

Template.tasksUserRowView.helpers
  'team': () -> share.Team.findOne(Template.instance().taskSignup.parentId)
  'task': () -> share.TeamTasks.findOne(Template.instance().taskSignup.shiftId)

Template.tasksUserRowView.events events

# this template is called with a leadsSignups
Template.leadsUserRowView.onCreated () ->
  template = this
  template.leadSignup = template.data
  sub = share.templateSub(template,"LeadsSignups.byUser", template.leadSignup.userId)

Template.leadsUserRowView.helpers
  'lead': () -> share.Lead.findOne(Template.instance().leadSignup.shiftId)
  'unit': () ->
    parentId = Template.instance().leasSignup.parentId
    t = share.Team.findOne(parentId)
    if t then t else
    dp = share.Department.findOne(parentId)
    if dp then dp else
    dv = share.Division.findOne(parentId)
    if dv then dv else
    console.log "??? #{parentId}"

Template.leadsUserRowView.events events
