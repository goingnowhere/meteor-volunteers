Template.teamShiftsTable.onCreated () ->
  template = this
  teamId = template.data._id
  sub = share.templateSub(template,"allDuties.byTeam",teamId)
  template.shifts = new ReactiveVar([])
  template.autorun () ->
    if sub.ready()
      template.shifts.set(share.getShifts({parentId: teamId}))

Template.teamShiftsTable.helpers
  'shifts': () -> Template.instance().shifts.get()

Template.teamShiftsTable.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    shift = share.TeamShifts.findOne(id)
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: shift})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "teamShifts.remove", id
  'click [data-action="clone"]': (event,template) ->
    id = $(event.target).data('id')
    shift = share.TeamShifts.findOne(id)
    delete shift._id
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: shift})

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
  'allLeads': () ->
    share.Lead.find({parentId: Template.instance().teamId}).map((lead) => {
      title: lead.title,
      userId: share.LeadSignups.findOne({ shiftId: lead._id })?.userId
    })
  'allTasks': () ->
    teamId = Template.instance().teamId
    status = Template.instance().taskFilter.get()
    share.TeamTasks.find({parentId: teamId, status: {$in: status}},{sort:{dueDate: 1}}).map((t) ->
      confirmed = share.TaskSignups.find({shiftId: t._id}).count()
      dueDate = moment(t.dueDate)
      needed = if t.min > 0 then t.min - confirmed else confirmed
      _.extend(t,
        timeleft: dueDate.diff(moment(), 'days')
        dueDate: dueDate
        confirmed: confirmed
        needed: needed)
    )
  'allDates': () ->
    teamId = Template.instance().teamId
    _.unique(share.TeamShifts.find({parentId: teamId}).map((s) ->
      moment(s.start).format('MMMM Do YYYY')
      ))
  'teamSignupsList': () => "teamSignupsList-#{share.eventName}"
}

Template.teamDayViewGrid.events
  'click [data-action="edit"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.Team}, data: template.data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "team.remove", id
  'click [data-action="addShift"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data:{parentId: template.data._id}})
  'click [data-action="addTask"]': (event,template) ->
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamTasks}, data:{parentId: template.data._id}})
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
  share.templateSub(template,"teamShifts.backend", template.data.teamId)

Template.teamShiftsView.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamShifts.findOne(id)
    ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "teamShifts.remove", id
