
Template.shiftsListItem.onCreated () ->
  template = this
  template.shift = template.data
  template.shiftId = template.shift._id
  template.parentId = template.shift.parentId
  share.templateSub(template,"TeamShifts.byShift", template.shiftId, Meteor.userId())

Template.shiftsListItem.events
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    parentId = $(event.target).data('parentid')
    selectedUser = $(".select-users[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "shiftSignups.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    parentId = $(event.target).data('parentid')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "shiftSignups.bail", doc

Template.shiftsListItem.helpers
  'shift': () -> share.TeamShifts.findOne(Template.instance().shiftId)
  'team': () -> share.Team.findOne(Template.instance().parentId)
  'signup': () ->
    userId = Meteor.userId()
    shiftId = Template.instance().shiftId
    share.ShiftSignups.findOne({userId: userId, shiftId: shiftId})

Template.shiftDate.helpers
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")

AutoForm.addHooks ['InsertTeamShiftsFormId','UpdateTeamShiftsFormId'],
  onSuccess: (formType, result) ->
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})
