Template.addLead.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.lead')

Template.addLead.helpers
  form: () -> { collection: share.Lead }

Template.leadsTable.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  console.log "FFFFFFFFF",template
  if template.data?._id
    template.subscribe('Volunteers.lead.backend',template.data._id)

Template.leadsTable.helpers
  'allLeads': () -> share.Lead.find()

AutoForm.addHooks ['InsertLeadFormId','UpdateLeadFormId'],
  onSuccess: (formType, result) ->
    console.log "ZZZ"
    this.template.data.var.set({add: false, teamId: result._id})
