Template.teamEdit.onCreated () ->
  template = this
  template.teamId = template.data._id
  share.templateSub(template,"ShiftSignups.byTeam",template.teamId)
  share.templateSub(template,"TaskSignups.byTeam",template.teamId)
  share.templateSub(template,"LeadSignups.byTeam",template.teamId)

Template.teamEdit.helpers
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
      tableFields: [ { name: 'title'}, {name: 'start',template: "shiftDate"} ]
      form: { collection: share.TeamShifts, filter: {parentId: parentId} }
      subscription : (template) ->
        [ share.templateSub(template,"ShiftSignups.byTeam",parentId) ]
      }
    task =  {
      id: "task"
      label: "tasks"
      tableFields: [ { name: 'title'}, {name: 'dueDate'} ]
      form: { collection: share.TeamTasks, filter: {parentId: parentId} }
      subscription : (template) ->
        [ share.templateSub(template,"TaskSignups.byTeam",parentId) ]
      }
    lead =  {
      'id': "leads"
      'label': "leads"
      'tableFields': [
        { name: 'userId', template: "teamLeadField"},
        { name: 'role' }
      ]
      'form': { collection: share.Lead, filter: {parentId: parentId} }
      'subscription': (template) ->
        [ share.templateSub(template,"LeadSignups.byTeam",parentId) ]
      }
    return [shift,task,lead]

Template.addTeam.onCreated () ->
  template = this
  template.departmentId = template.data.departmentId

Template.addTeam.helpers
  'form': () -> { collection: share.Team }
  'data': () -> { parentId : Template.instance().departmentId }

Template.addTeam.events
  'click [data-action="removeTeam"]': (event,template) ->
    teamId = $(event.target).data('id')
    share.meteorCall "team.remove", teamId

AutoForm.addHooks ['UpdateTeamFormId'],
  onSuccess: (formType, result) ->
    this.template.currentShift.set({teamId:result._id})
    this.template.currentTask.set({teamId:result._id})
    this.template.currentLead.set({teamId:result._id})

AutoForm.addHooks ['InsertTeamFormId'],
  onSuccess: (formType, result) ->
    console.log "modal close"
