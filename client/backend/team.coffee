
Template.addTeam.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.team')

Template.addTeam.events
  'click [data-action="removeTeam"]': (event,template) ->
    teamId = $(event.target).data('id')
    Meteor.call "Team.remove", teamId

Template.teamView.helpers
  'main': () ->
    id: "details"
    label: "details"
    form: { collection: share.Team }
    data: Template.currentData()
  'tabs': () ->
    parentId = if Template.currentData() then Template.currentData()._id
    shift =  {
      id: "shift"
      label: "shifts"
      tableFields: [ { name: 'title'}, {name: 'start',template: "shiftField"} ]
      form: { collection: share.TeamShifts }
      subscription : (template) ->
        [ template.subscribe('Volunteers.teamShifts.backend',parentId) ]
      }
    task =  {
      id: "task"
      label: "tasks"
      tableFields: [ { name: 'title'}, {name: 'dueDate'} ]
      form: { collection: share.TeamTasks }
      subscription : (template) ->
        [ template.subscribe('Volunteers.teamTasks.backend',parentId) ]
      }
    lead =  {
      id: "leads"
      label: "leads"
      tableFields: [
       { name: 'userId', template:"leadField"},
       { name: 'role' }
      ]
      form: { collection: share.Lead }
      subscription : (template) ->
        [ template.subscribe('Volunteers.users'),
         template.subscribe('Volunteers.lead.backend',parentId)
       ]
      }
    return [shift,task,lead]

AutoForm.addHooks ['InsertTeamFormId'],
  onSuccess: (formType, result) ->
    this.template.currentShift.set({teamId:result._id})
    this.template.currentTask.set({teamId:result._id})
    this.template.currentLead.set({teamId:result._id})
