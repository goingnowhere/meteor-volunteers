Template.volunteerFormBuilder.onCreated () ->
  template = this
  template.formUid = new ReactiveVar("VolunteerForm")
  template.colName = "Volunteers.volunteerForm"

Template.volunteerFormBuilder.helpers
  'formUid': () -> Template.instance().formUid
  'colName': () -> Template.instance().colName
  'name': () -> Template.instance().formUid.get()
