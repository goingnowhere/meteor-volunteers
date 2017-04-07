Template.addTeamTasks.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.teamsTasks')

Template.addTeamTasks.helpers
  form: () -> { collection: share.TeamTasks }

Template.tasksTable.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  console.log template.data
  template.subscribe('Volunteers.teamsTasks.backend',template.data._id)

Template.tasksTable.helpers
  'tasks': () -> share.TeamTasks.find()
  # 'getTasksUsers': (taskId) -> share.Tasks.findOne({shiftId: shiftId})

AutoForm.addHooks ['UpdateTeamTasksFormId'], #,'InsertTeamTasksFormId'],
  docToForm: (doc) ->
    doc.dueDate = moment(doc.dueDate).format("DD-MM-YYYY HH:mm")
    return doc
