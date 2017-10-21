# Template.addTeamTasks.onCreated () ->
#   template = this
#   template.subscribe('Volunteers.users')
#   template.subscribe('Volunteers.teamTasks')
#
# Template.addTeamTasks.helpers
#   form: () -> { collection: share.TeamTasks }

Template.tasksTable.onCreated () ->
  template = this
  share.templateSub(template,"users")
  if template.data?._id
    share.templateSub(template,"teamTasks.backend",template.data._id)

Template.tasksTable.helpers
  'allTasks': () -> share.TeamTasks.find()

AutoForm.addHooks ['InsertTeamTasksFormId','UpdateTeamTasksFormId'],
  onSuccess: (formType, result) ->
    if this.template.data.var
      this.template.data.var.set({add: false, teamId: result.teamId})
