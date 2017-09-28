Template.teamDayViewGrid.onCreated () ->
  template = this
  template.subscribe('Volunteers.teamShifts.backend',template.data._id)
  template.subscribe('Volunteers.teamTasks.backend',template.data._id)
  template.subscribe('Volunteers.lead.backend',template.data._id)
  template.subscribe('Volunteers.shifts')
  template.subscribe('Volunteers.users')
  template.taskFilter = new ReactiveVar(["pending","overdue","done"])

Template.teamDayViewGrid.helpers {
  'taskStatus': () -> [
    {status:"pending", isChecked:"checked"},
    {status:"overdue", isChecked:"checked"},
    {status:"done", isChecked:"checked"},
    {status:"archived"} ]
  'allLeads': () -> a = share.Lead.find().fetch() ; console.log a ; a
  'allTasks': () ->
    status = Template.instance().taskFilter.get()
    share.TeamTasks.find({status: {$in: status}},{sort:{dueDate: 1}}).map((t) ->
      confirmed = share.Shifts.find({shiftId: t._id}).count()
      dueDate = moment(t.dueDate)
      _.extend(t,
        timeleft: dueDate.diff(moment(), 'days')
        dueDate: dueDate.format('ddd, MMM Do')
        confirmed: confirmed
        vacant: t.max - confirmed)
    )
  'allShifts': () ->
    shifts = share.TeamShifts.find().map((s) ->
      _.extend(s,{day: moment(s.start).format('ddd, MMM Do')}))
    ss = _.groupBy(shifts, 'day')
    _.map(ss,(vl,k) ->
      totalVacant = 0
      totalConfirmed = 0
      vvl = _.map(_.sortBy(vl,'startTime'), (v) ->
        # status: confirmed
        confirmed = share.Shifts.find({shiftId: v._id}).count()
        totalConfirmed =+ confirmed
        totalVacant =+ (v.max - confirmed)
        _.extend(v,
          start: moment(v.start).format('h:mm a')
          end: moment(v.end).format('h:mm a')
          duration: moment.duration(v.end - v.start).humanize()
          confirmed: confirmed
          vacant: v.max - confirmed)
      )
      progress = ((totalVacant + totalConfirmed) / 100 ) * totalConfirmed
      # console.log "ff", totalVacant, totalConfirmed, progress
      teamId = Template.currentData()._id
      {date:k, shifts: vvl, progress: progress, teamId: teamId}
    )
  }

Template.teamDayViewGrid.events
  'click [data-action="edit"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.Team}, data:this})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    Meteor.call "Volunteers.team.remove", id
  'click [data-action="addShift"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data:{teamId: this._id}})
  'click [data-action="addTask"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamTasks}, data:{teamId: this._id}})
  'click #taskStatus': ( event, template ) ->
    selected = template.findAll( "#taskStatus:checked")
    template.taskFilter.set(_.map(selected, (i) -> i.defaultValue))

Template.teamTasksView.onCreated () ->
  template = this
  template.subscribe('Volunteers.teamTasks.backend',template.data.teamId)

Template.teamTasksView.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamTasks.findOne(id)
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamTasks}, data:data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    Meteor.call "Volunteers.teamTasks.remove", id
  'click [data-action="archive"]': (event,template) ->
    id = $(event.target).data('id')
    doc = {_id: id, modifier: {$set: {status: "archived"}}}
    Meteor.call "Volunteers.teamTasks.update", doc
  'click [data-action="toggle"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamTasks.findOne(id)
    status = if data.status == "done" then "pending" else "done"
    doc = {_id: id, modifier: {$set: {status: status}}}
    Meteor.call "Volunteers.teamTasks.update", doc

Template.teamShiftsView.onCreated () ->
  template = this
  template.subscribe('Volunteers.teamShifts.backend',template.data.teamId)

Template.teamShiftsView.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamShifts.findOne(id)
    console.log data
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data:data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    Meteor.call "Volunteers.teamShifts.remove", id
