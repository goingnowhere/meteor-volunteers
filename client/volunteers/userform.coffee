Template.addVolunteerForm.onCreated () ->
  template = this
  template.subscribe('FormBuilder.dynamicForms')
  share.templateSub(template,"volunteerForm")

# XXX this should be modified to allow the admin to edit the data of any
# user and not only display Meteor.userId() / the current user
Template.addVolunteerForm.helpers
  'form': () ->
    form = share.form.get()
    if form then {
      collection: form
      insert:
        label: i18n.__("abate:volunteers","create_volunteer_profile")
      update:
        label: i18n.__("abate:volunteers","update_volunteer_profile")
    }
  'data': () -> share.VolunteerForm.findOne({userId: Meteor.userId()})
