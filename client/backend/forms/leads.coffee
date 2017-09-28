Template.addLead.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.lead')

Template.addLead.helpers
  form: () -> { collection: share.Lead }
