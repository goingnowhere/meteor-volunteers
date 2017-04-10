Template.addDepartment.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.department')

Template.addDepartment.events
  'click [data-action="removeDept"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.department.remove", Id

Template.departmentView.onCreated () ->
  template = this
  sel = {}
  if template.data?._id then sel = {teamId: template.data._id}
  template.currentTeam = new ReactiveVar(sel)
  template.currentLead = new ReactiveVar(sel)

Template.departmentView.helpers
  'formDept': () -> { collection: share.Department }
  'formTeam': () -> { collection: share.Team }
  'formLead': () -> { collection: share.Lead }
  'currentTeam': () -> Template.instance().currentTeam.get()
  'currentLead': () -> Template.instance().currentLead.get()
  'currentTeamVar': () -> Template.instance().currentTeam
  'currentLeadVar': () -> Template.instance().currentLead

Template.departmentView.events
  'click [data-action="abandonLead"]': (event,template) ->
    Id = template.data._id
    template.currentLead.set({add: false, teamId: Id})
  'click [data-action="addLead"]': (event,template) ->
    Id = template.data._id
    template.currentLead.set({add: true, teamId: Id})
  'click [data-action="deleteLead"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.lead.remove", Id
  'click [data-action="editLead"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentLead.set(share.Lead.findOne(Id))

  'click [data-action="abandonTeam"]': (event,template) ->
    Id = template.data._id
    template.currentTeam.set({add: false, teamId: Id})
  'click [data-action="addTeam"]': (event,template) ->
    Id = template.data._id
    template.currentTeam.set({add: true, teamId: Id})
  'click [data-action="deleteTeam"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.team.remove", Id
  'click [data-action="editTeam"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentTeam.set(share.Team.findOne(Id))

AutoForm.addHooks ['InsertDepartmentFormId'],
  onSuccess: (formType, result) ->
    this.template.currentTeam.set({teamId:result._id})
    this.template.currentLead.set({teamId:result._id})
