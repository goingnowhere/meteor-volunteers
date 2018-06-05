events =
  'click [data-action="edit"]': ( event, template ) ->
    type = $(event.currentTarget).data('type')
    if type == 'project'
      shiftId = $(event.currentTarget).data('shiftid')
      parentId = $(event.currentTarget).data('parentid')
      selectedUser = $("[data-shiftId='#{shiftId}']").val()
      userId = $(event.currentTarget).data('userid')
      doc = {parentId: parentId, shiftId: shiftId, userId: userId}
      project = share.Projects.findOne(shiftId)
      signup = share.ProjectSignups.findOne(doc)
      AutoFormComponents.ModalShowWithTemplate("projectSignupForm",{ project, signup})

  'click [data-action="info"]': ( event, template ) ->
    shiftId = $(event.currentTarget).data('shiftid')
    type = $(event.currentTarget).data('type')
    parentId = $(event.currentTarget).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = $(event.currentTarget).data('userid')
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    team = share.Team.findOne(parentId)
    switch type
      when 'project'
        duty = _.extend(share.Projects.findOne(shiftId),{type: 'project'})
        break
      when 'shift'
        duty = _.extend(share.TeamShifts.findOne(shiftId),{type: 'shift'})
        break
      else
        break
    duty = _.extend(duty, {team})
    AutoFormComponents.ModalShowWithTemplate("dutyListItem",duty)

  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.currentTarget).data('shiftid')
    type = $(event.currentTarget).data('type')
    parentId = $(event.currentTarget).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = $(event.currentTarget).data('userid')
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.bail", doc

Template.bookedTable.bindI18nNamespace('abate:volunteers')

Template.bookedTable.onCreated () ->
  template = this
  { data } = template
  if data?.userId?
    template.userId = data.userId
  else
    template.userId = Meteor.userId()
  template.autorun () ->
    share.templateSub(template,"ShiftSignups.byUser", template.userId)
    share.templateSub(template,"ProjectsSignups.byUser", template.userId)
    share.templateSub(template,"LeadSignups.byUser", template.userId)

Template.bookedTable.helpers
  'allShifts': () ->
    userId = Template.instance().userId
    sel = {userId: userId, status: {$in: ["confirmed","pending"]}}
    shiftSignups = share.ShiftSignups.find(sel)
      .map((signup) -> _.extend({}, signup, {type: 'shift'}))
    projectSignups = share.ProjectSignups.find(sel)
      .map((signup) -> _.extend({}, signup, {type: 'project'}))
    leadSignups = share.LeadSignups.find({status: "pending"})
      .map((signup) -> _.extend({}, signup, {type: 'lead'}))
    _.chain(leadSignups.concat(shiftSignups.concat(projectSignups)))
    .sortBy((s) -> s.start)
    .value()

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

# this template is called with a taskSignups
Template.tasksUserRowView.bindI18nNamespace('abate:volunteers')
Template.tasksUserRowView.onCreated () ->
  template = this
  template.taskSignup = template.data
  sub = share.templateSub(template,"TasksSignups.byUser", template.taskSignup.userId)

Template.tasksUserRowView.helpers
  'team': () -> share.Team.findOne(Template.instance().taskSignup.parentId)
  'task': () -> share.TeamTasks.findOne(Template.instance().taskSignup.shiftId)

Template.tasksUserRowView.events events

# this template is called with a leadsSignups
Template.leadsUserRowView.bindI18nNamespace('abate:volunteers')
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
