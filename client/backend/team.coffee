
Template.addTeam.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.team')

Template.addTeam.events
  'click [data-action="removeTeam"]': (event,template) ->
    teamId = $(event.target).data('id')
    Meteor.call "Team.remove", teamId

Template.teamView.onCreated () ->
  template = this
  sel = {}
  if template.data?._id then sel = {teamId: template.data._id}
  template.currentShift = new ReactiveVar(sel)
  template.currentTask = new ReactiveVar(sel)
  template.currentLead = new ReactiveVar(sel)

Template.teamView.helpers
  'formTeam': () -> { collection: share.Team }
  'formShift': () -> { collection: share.TeamShifts }
  'formTask': () -> { collection: share.TeamTasks }
  'formLead': () -> { collection: share.Lead }
  'currentShift': () -> Template.instance().currentShift.get()
  'currentTask': () -> Template.instance().currentTask.get()
  'currentLead': () -> Template.instance().currentLead.get()
  'currentShiftVar': () -> Template.instance().currentShift
  'currentTaskVar': () -> Template.instance().currentTask
  'currentLeadVar': () -> Template.instance().currentLead

Template.teamView.events
  'click [data-action="abandonLead"]': (event,template) ->
    Id = template.data._id
    template.currentLead.set({add: false, teamId: Id})
  'click [data-action="addLead"]': (event,template) ->
    Id = template.data._id
    template.currentLead.set({add: true, teamId: Id})
  'click [data-action="deleteLead"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "volunteers.lead.remove", Id
  'click [data-action="editLead"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentLead.set(share.Lead.findOne(Id))

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

AutoForm.addHooks ['InsertTeamFormId'],
  onSuccess: (formType, result) ->
    this.template.currentShift.set({teamId:result._id})
    this.template.currentTask.set({teamId:result._id})
    this.template.currentLead.set({teamId:result._id})
