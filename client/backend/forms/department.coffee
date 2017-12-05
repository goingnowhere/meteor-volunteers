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
        [ share.templateSub(template,"team.backend",parentId) ]
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
        [ share.templateSub(template,"users"),
          share.templateSub(template,"lead.backend",parentId) ]
      }
    return [team,lead]

AutoForm.addHooks ['InsertDepartmentFormId'],
  onSuccess: (formType, result) ->
    console.log this.template
    # this.template.currentLead.set({teamId:result._id})

Template.departmentsList.onCreated () =>
  share.meteorSub('department')

Template.departmentsList.helpers
  departments: () => share.Department.find()
  departmentView: () => "departmentView-#{share.eventName1.get()}"
