Template.addTeamShifts.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.teamShifts')

Template.addTeamShifts.helpers
  form: () -> { collection: share.TeamShifts }

Template.shiftsTable.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.teamShifts.backend',template.data._id)

Template.shiftsTable.helpers
  'allShifts': () -> share.TeamShifts.find()

# we need this hook to transform the date from autoform in something
# that the date picker can shallow. This should be done by the datetimepicker
# parsing function, but I'm not able to make it work
AutoForm.addHooks ['UpdateTeamShiftsFormId'], #,'InsertTeamShiftsFormId'],
  docToForm: (doc) ->
    doc.start = moment(doc.start).format("DD-MM-YYYY HH:mm")
    doc.end = moment(doc.end).format("DD-MM-YYYY HH:mm")
    console.log "zzZ",doc
    return doc
  # onSuccess: (formType,result) ->
