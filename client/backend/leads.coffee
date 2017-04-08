Template.addTeamLeads.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.teamLeads')

Template.addTeamLeads.helpers
  form: () -> { collection: share.TeamLeads }

Template.leadsTable.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  if template.data?._id
    template.subscribe('Volunteers.teamLeads.backend',template.data._id)

Template.leadsTable.helpers
  'allLeads': () -> share.TeamLeads.find()

AutoForm.addHooks ['InsertTeamLeadsFormId','UpdateTeamLeadsFormId'],
  onSuccess: (formType, result) ->
    this.template.data.var.set({add: false, teamId: Id})
