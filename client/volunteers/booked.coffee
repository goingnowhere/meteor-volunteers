events =
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.bail", doc

Template.bookedTable.bindI18nNamespace('abate:volunteers')
Template.bookedTable.helpers
  'allShifts': (userId) ->
    sel = {userId: Meteor.userId(), status: {$in: ["confirmed","pending"]}}
    shiftSignups = share.ShiftSignups.find(sel)
      .map((signup) -> _.extend({}, signup, {type: 'shift'}))
    projectSignups = share.ProjectSignups.find(sel)
      .map((signup) -> _.extend({}, signup, {type: 'project'}))
    leadSignups = share.LeadSignups.find({status: "pending"})
      .map((signup) -> _.extend({}, signup, {type: 'lead'}))
    return leadSignups.concat(shiftSignups.concat(projectSignups))

Template.bookedTable.events events

Template.signupUserRowView.bindI18nNamespace('abate:volunteers')
# this template is called with a shift or project signup
Template.signupUserRowView.onCreated () ->
  template = this
  template.signup = template.data.signup

Template.signupUserRowView.helpers
  team: () -> share.Team.findOne(Template.instance().signup.parentId)
  duty: () ->
    type = Template.instance().signup.type
    shiftId = Template.instance().signup.shiftId
    switch type
      when "shift" then share.TeamShifts.findOne(shiftId)
      when "project" then share.Projects.findOne(shiftId)
      when "lead" then share.Lead.findOne(shiftId)

Template.signupUserRowView.events events

Template.tasksUserRowView.bindI18nNamespace('abate:volunteers')
# this template is called with a taskSignups
Template.tasksUserRowView.onCreated () ->
  template = this
  template.taskSignup = template.data
  sub = share.templateSub(template,"TasksSignups.byUser", template.taskSignup.userId)

Template.tasksUserRowView.helpers
  'team': () -> share.Team.findOne(Template.instance().taskSignup.parentId)
  'task': () -> share.TeamTasks.findOne(Template.instance().taskSignup.shiftId)

Template.tasksUserRowView.events events

Template.leadsUserRowView.bindI18nNamespace('abate:volunteers')
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
