
share.eventUsers = () ->
  Meteor.users.find().fetch()

Template.shiftsTasksTableView.onRendered () ->
  template = this
  if share.isManagerOrLead(Meteor.userId()) && template.data.enroll
    sub = share.templateSub(template,"users")
    template.autorun () ->
      if sub.ready()
        data = _.reduce(share.eventUsers(),((acc,t) ->
          acc.push {id: t._id, text: share.getUserName t}
          return acc),
          [{id: "-1", text: (TAPi18n.__ "enroll_user")}]
        )
        $(".select-users").select2({
          placeholder: 'Select an user to Enroll',
          data: data
        })

events =
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    parentId = $(event.target).data('parentid')
    type = $(event.target).data('type')
    selectedUser = $(".select-users[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    parentId = $(event.target).data('parentid')
    type = $(event.target).data('type')
    selectedUser = $("[data-shiftId='#{shiftId}']").val()
    userId = if selectedUser && (selectedUser != "-1") then selectedUser else Meteor.userId()
    doc = {parentId: parentId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.bail", doc

Template.shiftsTasksTableView.events events
# Template.shiftsTasksTableRowView.events events

helpers =
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")
  'teamViewEventName': () -> 'teamView-'+share.eventName
  # XXX here with this permission any lead can enroll somebody for a shift ...
  'isManagerOrLead': () -> share.isManagerOrLead(Meteor.userId()) && Template.instance().data.enroll

Template.shiftsTasksTableView.helpers helpers
Template.shiftsTasksTableRowView.helpers helpers
