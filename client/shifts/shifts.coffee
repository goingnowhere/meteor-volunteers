Template.dutiesListItem.bindI18nNamespace('abate:volunteers')
Template.dutiesListItem.onCreated () ->
  template = this
  template.duty = template.data
  share.templateSub(template,"TeamShifts.byDuty", template.duty._id, Meteor.userId())
  share.templateSub(template,"TeamTasks.byDuty", template.duty._id, Meteor.userId())
  share.templateSub(template,"Lead.byDuty", template.duty._id, Meteor.userId())

Template.dutiesListItem.events
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    selectedUser = $(".select-users[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    if type == "shift"
      share.meteorCall "shiftSignups.insert", doc
    else if type == "task"
      share.meteorCall "taskSignups.insert", doc
    else if type == "lead"
      share.meteorCall "leadSignups.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    type = $(event.target).data('type')
    parentId = $(event.target).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    if type == "shift"
      share.meteorCall "shiftSignups.bail", doc
    else if type == "task"
      share.meteorCall "taskSignups.bail", doc
    else if type == "lead"
      share.meteorCall "leadSignups.bail", doc

Template.dutiesListItem.helpers
  'duty': () -> Template.instance().duty
  'team': () ->
    duty = Template.instance().duty
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
    duty = Template.instance().duty
    if duty.type == "shift"
      return share.ShiftSignups.findOne({userId: userId, shiftId: duty._id})
    else if duty.type == "task"
      return share.TaskSignups.findOne({userId: userId, shiftId: duty._id})
    else if duty.type == "lead"
      return share.LeadSignups.findOne({userId: userId, shiftId: duty._id})

Template.shiftDate.helpers
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")

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

AutoForm.addHooks ['InsertTeamShiftsFormId','UpdateTeamShiftsFormId'],
  onSuccess: (formType, result) ->
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})
