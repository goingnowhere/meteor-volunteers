Template.teamDayViewGrid.onCreated () ->
  template = this
  template.taskFilter = new ReactiveVar(["pending","overdue","done"])
  template.teamId = template.data._id
  share.templateSub(template,"allDuties.byTeam", template.teamId)
  share.templateSub(template,"users")

Template.teamDayViewGrid.helpers {
  'taskStatus': () -> [
    {status:"pending", isChecked:"checked"},
    {status:"overdue", isChecked:"checked"},
    {status:"done", isChecked:"checked"},
    {status:"archived"} ]
  'allLeads': () -> share.Lead.find({parentId: Template.instance().teamId})
  'allTasks': () ->
    teamId = Template.instance().teamId
    status = Template.instance().taskFilter.get()
    share.TeamTasks.find({parentId: teamId, status: {$in: status}},{sort:{dueDate: 1}}).map((t) ->
      confirmed = share.TaskSignups.find({shiftId: t._id}).count()
      dueDate = moment(t.dueDate)
      vacant = if t.max > 0 then t.max - confirmed else confirmed
      _.extend(t,
        timeleft: dueDate.diff(moment(), 'days')
        dueDate: dueDate
        confirmed: confirmed
        vacant: vacant)
    )
  'allShifts': () ->
    teamId = Template.instance().teamId
    shifts = share.TeamShifts.find({parentId: teamId}).map((s) ->
      _.extend(s,{day: moment(s.start).format('MMMM Do YYYY')}))
    ss = _.groupBy(shifts, 'day')
    _.map(ss,(vl,k) ->
      totalVacant = 0
      totalConfirmed = 0
      vvl = _.map(_.sortBy(vl,'startTime'), (v) ->
        # status: confirmed
        confirmed = share.ShiftSignups.find({shiftId: v._id}).count()
        totalConfirmed =+ confirmed
        totalVacant =+ (v.max - confirmed)
        _.extend(v,
          start: v.start
          end: v.end
          policy: v.policy
          duration: moment.duration(v.end - v.start).humanize()
          confirmed: confirmed
          vacant: v.max - confirmed)
      )
      progress = ((totalVacant + totalConfirmed) / 100 ) * totalConfirmed
      teamId = Template.currentData()._id
      {date:k, shifts: vvl, progress: progress, teamId: teamId}
    )
  # pathFor
  'teamSignupList': () => "teamSignupsList-#{share.eventName1.get()}"

  }

Template.teamDayViewGrid.events
  'click [data-action="edit"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.Team}, data:this})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "team.remove", id
  'click [data-action="addShift"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data:{parentId: this._id}})
  'click [data-action="addTask"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamTasks}, data:{parentId: this._id}})
  'click #taskStatus': ( event, template ) ->
    selected = template.findAll("#taskStatus:checked")
    template.taskFilter.set(_.map(selected, (i) -> i.defaultValue))

Template.teamTasksView.onCreated () ->
  template = this
  share.templateSub(template,"teamTasks.backend",template.data.teamId)

Template.teamTasksView.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamTasks.findOne(id)
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamTasks}, data: data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "teamTasks.remove", id
  'click [data-action="archive"]': (event,template) ->
    id = $(event.target).data('id')
    doc = {_id: id, modifier: {$set: {status: "archived"}}}
    share.meteorCall "teamTasks.update", doc
  'click [data-action="toggle"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamTasks.findOne(id)
    status = if data.status == "done" then "pending" else "done"
    doc = {_id: id, modifier: {$set: {status: status}}}
    share.meteorCall "teamTasks.update", doc

Template.teamShiftsView.onCreated () ->
  template = this
  share.templateSub(template,"teamShifts.backend",template.data.teamId)

Template.teamShiftsView.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamShifts.findOne(id)
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "teamShifts.remove", id
