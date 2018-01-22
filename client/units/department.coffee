Template.departmentEdit.helpers
  'main': () ->
    id: "details"
    label: i18n.__("abate:volunteers","details")
    form: { collection: share.Department }
    data: Template.currentData()
  'tabs': () ->
    parentId = if Template.currentData() then Template.currentData()._id
    team =  {
      id: "team"
      label: i18n.__("abate:volunteers","team")
      tableFields: [ { name: 'name'} ]
      form: { collection: share.Team }
      subscription : (template) ->
        [ share.templateSub(template,"team.backend",parentId) ]
      }
    lead =  {
      id: "leads"
      label: i18n.__("abate:volunteers","leads")
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
