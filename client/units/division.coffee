import { collections } from '../../both/collections/initCollections'

Template.addDivision.onCreated () ->
  template = this
  share.templateSub(template,"users")
  share.templateSub(template,"division")

Template.addDivision.events
  'click [data-action="removeDivision"]': (event,template) ->
    Id = $(event.target).data('id')
    share.meteorCall "division.remove", Id

Template.divisionEdit.helpers
  'main': () ->
    id: "details"
    label: i18n.__("goingnowhere:volunteers","details")
    form: { collection: collections.division }
    data: Template.currentData()
  'tabs': () ->
    parentId = if Template.currentData() then Template.currentData()._id
    dept = {
      id: "dept"
      label: i18n.__("goingnowhere:volunteers","departments")
      tableFields: [ { name: 'name'} ]
      form: { collection: collections.department }
      subscription : (template) ->
        [ share.templateSub(template,"department.backend",parentId) ]
      }
    lead = {
      id: "leads"
      label: i18n.__("goingnowhere:volunteers","leads")
      tableFields: [
        { name: 'userId', template:"leadField"},
        { name: 'role' }
      ]
      form: { collection: collections.lead }
      subscription : (template) ->
        [ share.templateSub(template,"users"),
          share.templateSub(template,"lead.backend",parentId)
        ]
      }
    return [dept,lead]

# AutoForm.addHooks ['InsertDivisionFormId'],
#   onSuccess: (formType, result) ->
#     router.go ...
