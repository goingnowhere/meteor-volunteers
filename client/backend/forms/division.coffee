Template.addDivision.onCreated () ->
  template = this
  share.templateSub(template,"users")
  share.templateSub(template,"division")

Template.addDivision.events
  'click [data-action="removeDivision"]': (event,template) ->
    Id = $(event.target).data('id')
    share.meteorCall "division.remove", Id

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
        [ share.templateSub(template,"department.backend",parentId) ]
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
        [ share.templateSub(template,"users"),
          share.templateSub(template,"lead.backend",parentId)
        ]
      }
    return [dept,lead]

# AutoForm.addHooks ['InsertDivisionFormId'],
#   onSuccess: (formType, result) ->
#     router.go ...
