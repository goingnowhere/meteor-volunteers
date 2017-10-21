# Template.addTeamShifts.onCreated () ->
#   template = this
#   template.subscribe('Volunteers.users')
#   template.subscribe('Volunteers.teamShifts')
#
# Template.addTeamShifts.helpers
#   form: () -> { collection: share.TeamShifts }
#
Template.shiftsTable.onCreated () ->
  template = this
  share.templateSub(template,"users")
  if template.data?._id
    share.templateSub(template,"teamShifts.backend",template.data._id)

Template.shiftsTable.helpers
  'allShifts': () -> share.TeamShifts.find()

# we need this hook to transform the date from autoform in something
# that the date picker can shallow. This should be done by the datetimepicker
# parsing function, but I'm not able to make it work
AutoForm.addHooks ['InsertTeamShiftsFormId','UpdateTeamShiftsFormId'],
  onSuccess: (formType, result) ->
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})
