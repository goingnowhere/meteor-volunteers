Template.addDivision.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.division')

Template.addDivision.events
  'click [data-action="removeDivision"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.division.remove", Id

Template.divisionView.helpers
  'main': () ->
    id: "details"
    label: "details"
    form: { collection: share.Division }
    data: Template.currentData()
  'tabs': () ->
    parentId = if Template.currentData() then Template.currentData()._id
    dept = {
      id: "dept"
      label: "departments"
      tableFields: [ { name: 'name'} ]
      form: { collection: share.Department }
      subscription : (template) ->
        [ template.subscribe('Volunteers.department.backend',parentId) ]
      }
    lead = {
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
    return [dept,lead]

# AutoForm.addHooks ['InsertDivisionFormId'],
#   onSuccess: (formType, result) ->
#     router.go ...
