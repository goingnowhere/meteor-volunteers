Template.addDepartment.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.department')

Template.addDepartment.events
  'click [data-action="removeDept"]': (event,template) ->
    id = $(event.target).data('id')
    Meteor.call "Volunteers.department.remove", id

Template.departmentView.helpers
  'main': () ->
    id: "details"
    label: "details"
    form: { collection: share.Department }
    data: Template.currentData()
  'tabs': () ->
    parentId = if Template.currentData() then Template.currentData()._id
    team =  {
      id: "team"
      label: "teams"
      tableFields: [ { name: 'name'} ]
      form: { collection: share.Team }
      subscription : (template) ->
        [ template.subscribe('Volunteers.team.backend',parentId) ]
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
    return [team,lead]

AutoForm.addHooks ['InsertDepartmentFormId'],
  onSuccess: (formType, result) ->
    console.log this.template
    # this.template.currentLead.set({teamId:result._id})
