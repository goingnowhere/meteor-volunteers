
Template.teamEditDetails.bindI18nNamespace('goingnowhere:volunteers')
Template.teamEditDetails.helpers
  'form': () -> { collection: share.Team }
  'data': () -> Template.currentData()

Template.teamEdit.bindI18nNamespace('goingnowhere:volunteers')
Template.teamEdit.onCreated () ->
  template = this
  template.teamId = template.data._id
  share.templateSub(template,"ShiftSignups.byTeam",template.teamId)
  share.templateSub(template,"TaskSignups.byTeam",template.teamId)
  share.templateSub(template,"LeadSignups.byTeam",template.teamId)

Template.teamEdit.helpers
  'main': () ->
    id: "details"
    label: i18n.__("goingnowhere:volunteers","details")
    form: { collection: share.Team }
    data: Template.currentData()
  'tabs': () ->
    parentId = if Template.currentData() then Template.currentData()._id
    shift =  {
      id: "shift"
      label: i18n.__("goingnowhere:volunteers","shifts")
      # TODO Convert multiAddView to use React
      tableFields: [ { name: 'title'}, {name: 'start',template: "shiftDateInline"} ]
      form: { collection: share.TeamShifts, filter: {parentId: parentId} }
      subscription : (template) ->
        [ share.templateSub(template,"ShiftSignups.byTeam",parentId) ]
      }
    task =  {
      id: "task"
      label: i18n.__("goingnowhere:volunteers","tasks")
      tableFields: [ { name: 'title'}, {name: 'dueDate'} ]
      form: { collection: share.TeamTasks, filter: {parentId: parentId} }
      subscription : (template) ->
        [ share.templateSub(template,"TaskSignups.byTeam",parentId) ]
      }
    lead =  {
      'id': "leads"
      'label': i18n.__("goingnowhere:volunteers","leads")
      'tableFields': [
        { name: 'title' },
        { name: 'userId', template: "teamLeadField"},
      ]
      'form': { collection: share.Lead, filter: {parentId: parentId} }
      'subscription': (template) ->
        [ share.templateSub(template,"LeadSignups.byTeam",parentId) ]
      }
    return [shift,task,lead]

Template.addTeam.bindI18nNamespace('goingnowhere:volunteers')
Template.addTeam.onCreated () ->
  template = this
  template.departmentId = template.data.departmentId

Template.addTeam.helpers
  'form': () -> { collection: share.Team }
  'data': () -> { parentId : Template.instance().departmentId }

Template.addTeam.events
  'click [data-action="removeTeam"]': (event,template) ->
    teamId = $(event.currentTarget).data('id')
    share.meteorCall "team.remove", teamId

Template.teamLeadField.bindI18nNamespace('goingnowhere:volunteers')
Template.teamLeadField.onCreated () ->
  template = this
  share.templateSub(template,"LeadSignups.byTeam",template.data.parentId)
  share.templateSub(template,"LeadSignups.byDepartment",template.data.parentId)

Template.teamLeadField.helpers
  'signup': () ->
    parentId = Template.currentData().parentId
    shiftId = Template.currentData()._id
    share.LeadSignups.findOne({parentId: parentId, shiftId: shiftId, status: 'confirmed'})
