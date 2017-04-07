
Template.addTeam.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.teams')
  template.currentQuote = new ReactiveVar()
  template.currentBill = new ReactiveVar()

Template.addTeam.helpers

Template.addTeam.events
  'click [data-action="removeTeam"]': (event,template) ->
    teamId = $(event.target).data('id')
    Meteor.call "Teams.remove", teamId

Template.teamsView.onCreated () ->
  template = this
  sel = {}
  if template.data
    if template.data._id then sel = {teamId: template.data._id}
  template.currentShift = new ReactiveVar(sel)
  template.currentTask = new ReactiveVar(sel)

Template.teamsView.helpers
  'formTeam': () -> { collection: share.Teams }
  'formShift': () -> { collection: share.TeamShifts }
  'formTask': () -> { collection: share.TeamTasks }
  'currentShift': () -> Template.instance().currentShift.get()
  'currentTask': () -> Template.instance().currentTask.get()

Template.teamsView.events
  'click [data-action="abandonShift"]': (event,template) ->
    Id = template.data._id
    template.currentShift.set({add: false, teamId: Id})
  'click [data-action="addShift"]': (event,template) ->
    Id = template.data._id
    template.currentShift.set({add: true, teamId: Id})
  'click [data-action="deleteShift"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "volunteers.teamShifts.remove", Id
  'click [data-action="editShift"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentShift.set(share.TeamShifts.findOne(Id))

  'click [data-action="abandonTask"]': (event,template) ->
    Id = template.data._id
    template.currentTask.set({add: false, teamId: Id})
  'click [data-action="addTask"]': (event,template) ->
    Id = template.data._id
    template.currentTask.set({add: true, teamId: Id})
  'click [data-action="deleteTask"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "volunteers.teamTasks.remove", Id
  'click [data-action="editTask"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentTask.set(share.TeamTasks.findOne(Id))

AutoForm.addHooks ['insertTeamFormId'],
  onSuccess: (formType, result) ->
    console.log this
    console.log result
    this.template.currentShift.set({teamId:result._id})
    this.template.currentTask.set({teamId:result._id})
