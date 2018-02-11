Template.teamShiftsTable.bindI18nNamespace('abate:volunteers')
Template.teamShiftsTable.onCreated () ->
  template = this
  teamId = template.data._id
  sub = share.templateSub(template,"ShiftSignups.byTeam",teamId)
  sub = share.templateSub(template,"LeadSignups.byTeam",teamId)
  sub = share.templateSub(template,"TaskSignups.byTeam",teamId)
  sub = share.templateSub(template,"ProjectSignups.byTeam",teamId)
  template.shifts = new ReactiveVar([])
  template.grouping = new ReactiveVar(new Set())
  template.autorun () ->
    if sub.ready()
      template.shifts.set(share.getShifts({parentId: teamId}))

Template.teamShiftsTable.helpers
  'grouping': () -> Template.instance().grouping.get().size > 0
  'groupedShifts': () ->
    f = _.groupBy(Template.instance().shifts.get(), (shift) -> shift.title)
    _.map(f,(v,k) ->
      id = Random.id()
      g = _.groupBy(v, (shift) -> if shift.groupId then shift.groupId else shift._id)
      title: k
      class: "family-#{id}"
      groups: _.map(g,(v,k) -> {group:k, shifts:v} )
    )

Template.teamShiftsTable.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    shift = share.TeamShifts.findOne(id)
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: shift})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "teamShifts.remove", id
  'click [data-action="clone"]': (event,template) ->
    id = $(event.target).data('id')
    shift = share.TeamShifts.findOne(id)
    delete shift._id
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: shift})
  'click tr.shift': (event,template) ->
    g = template.grouping.get()
    if g.size > 0
      tr = $(event.target).parent()
      id = tr.data('id')
      # this "if" is needed because the action "group" triggers also this event
      # and I don't understand how to prenvent the propagation without killing
      # the dropdown
      if id
        if tr.hasClass('bg-info')
          g = g.delete(id)
          tr.removeClass('bg-info')
        else
          g = g.add(id)
          tr.addClass('bg-info')
        template.grouping.set(g)
  'click [data-action="group"]': (event,template) ->
    # event.stopPropagation()
    # event.preventDefault()
    g = template.grouping.get()
    id = $(event.target).data('id')
    $("tr.shift[data-id='#{id}']").addClass('bg-info')
    template.grouping.set((new Set()).add(id))
  'click [data-action="groupDone"]': (event,template) ->
    $("tr.shift").removeClass('bg-info')
    groupId = Random.id()
    template.grouping.get().forEach (id) ->
      doc = {_id: id, modifier: {$set: {groupId: groupId}}}
      share.meteorCall "teamShifts.update", doc
    template.grouping.set(new Set())
  'click [data-action="removeFromGroup"]': (event,template) ->
    id = $(event.target).data('id')
    doc = {_id: id, modifier: {$unset: {groupId: ""}}}
    share.meteorCall "teamShifts.update", doc

Template.teamDayViewGrid.bindI18nNamespace('abate:volunteers');
Template.teamDayViewGrid.onCreated () ->
  template = this
  template.taskFilter = new ReactiveVar(["pending","overdue","done"])
  template.teamId = template.data._id
  sub = share.templateSub(template,"ShiftSignups.byTeam",template.teamId)
  sub = share.templateSub(template,"LeadSignups.byTeam",template.teamId)
  sub = share.templateSub(template,"TaskSignups.byTeam",template.teamId)
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
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.Team}, data: template.data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "team.remove", id
  'click [data-action="addShift"]': (event,template) ->
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data:{parentId: template.data._id}})
  'click [data-action="addTask"]': (event,template) ->
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamTasks}, data:{parentId: template.data._id}})
  'click #taskStatus': ( event, template ) ->
    selected = template.findAll("#taskStatus:checked")
    template.taskFilter.set(_.map(selected, (i) -> i.defaultValue))

Template.teamTasksView.bindI18nNamespace('abate:volunteers');
Template.teamTasksView.onCreated () ->
  template = this
  share.templateSub(template,"teamTasks.backend",template.data.teamId)

Template.teamTasksView.events
  'click [data-action="edit"]': (event,template) ->
    id = $(event.target).data('id')
    data = share.TeamTasks.findOne(id)
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
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
    AutoFormComponents.ModalShowWithTemplate("insertUpdateTemplate",
      {form:{collection: share.TeamShifts}, data: data})
  'click [data-action="delete"]': (event,template) ->
    id = $(event.target).data('id')
    share.meteorCall "teamShifts.remove", id
