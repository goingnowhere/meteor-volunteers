import { collections } from '../../both/collections/initCollections'

Template.teamEditDetails.bindI18nNamespace('goingnowhere:volunteers')
Template.teamEditDetails.helpers
  'form': () -> { collection: share.Team }
  'data': () -> Template.currentData()

Template.teamEdit.bindI18nNamespace('goingnowhere:volunteers')
Template.teamEdit.onCreated () ->
  template = this
  template.teamId = template.data._id
  share.templateSub(template,"Signups.byTeam",template.teamId,'shift')
  share.templateSub(template,"Signups.byTeam",template.teamId,'task')
  share.templateSub(template,"Signups.byTeam",template.teamId,'lead')

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
        [ share.templateSub(template,"Signups.byTeam",parentId, 'shift') ]
      }
    task =  {
      id: "task"
      label: i18n.__("goingnowhere:volunteers","tasks")
      tableFields: [ { name: 'title'}, {name: 'dueDate'} ]
      form: { collection: share.TeamTasks, filter: {parentId: parentId} }
      subscription : (template) ->
        [ share.templateSub(template,"Signups.byTeam",parentId, 'task') ]
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
        [ share.templateSub(template,"Signups.byTeam",parentId, 'lead') ]
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
  share.templateSub(template,"Signups.byTeam",template.data.parentId, 'lead')
  share.templateSub(template,"Signups.byDept",template.data.parentId, 'lead')

Template.teamLeadField.helpers
  'signup': () ->
    parentId = Template.currentData().parentId
    shiftId = Template.currentData()._id
    collections.signups.findOne({parentId: parentId, shiftId: shiftId, status: 'confirmed'})
