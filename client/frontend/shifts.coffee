Template.shiftsTasksTableView.events
  'click [data-action="apply"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    teamId = $(event.target).data('teamid')
    type = $(event.target).data('type')
    userId = Meteor.userId()
    doc = {teamId:teamId,shiftId:shiftId,userId: userId,type:type}
    Meteor.call "Volunteers.shifts.insert", doc
  'click [data-action="bail"]': ( event, template ) ->
    shiftId = $(event.target).data('shiftid')
    teamId = $(event.target).data('teamid')
    type = $(event.target).data('type')
    userId = Meteor.userId()
    doc = {teamId:teamId,shiftId:shiftId,userId: userId,type:type}
    Meteor.call "Volunteers.shifts.bail", doc