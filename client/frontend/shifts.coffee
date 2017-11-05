events =
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    teamId = $(event.target).data('teamid')
    type = $(event.target).data('type')
    userId = Meteor.userId()
    doc = {teamId: teamId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    teamId = $(event.target).data('teamid')
    type = $(event.target).data('type')
    userId = Meteor.userId()
    doc = {teamId: teamId, shiftId: shiftId, userId: userId}
    share.meteorCall "#{type}Signups.bail", doc

Template.shiftsTasksTableView.events events
# Template.shiftsTasksTableRowView.events events

helpers =
  'sameDay': (start, end) -> moment(start).isSame(moment(end),"day")
  'teamViewEventName': () -> 'teamView-'+share.eventName1.get()

Template.shiftsTasksTableView.helpers helpers
Template.shiftsTasksTableRowView.helpers helpers
