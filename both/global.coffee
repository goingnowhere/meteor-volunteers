share.getUserName  = AutoFormComponents.getUserName
share.getUserEmail = AutoFormComponents.getUserEmail

share.templateSub = (template,name,args...) ->
  template.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

share.meteorSub = (name,args...) ->
  Meteor.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

share.meteorCall = (name,args...,lastArg) ->
  if typeof lastArg == 'function'
    callback = lastArg
  else
    args.push(lastArg)
  Meteor.call("#{share.eventName}.Volunteers.#{name}", args... , (err,res) ->
    if !callback && err
      Bert.alert({
        title: i18n.__("abate:volunteers","method_error"),
        message: err.reason,
        type: 'danger',
        style: 'growl-top-right',
      })
    if callback
      callback(err,res)
    )

share.getOrgUnit = (unitId) ->
  if unitId
    team = share.Team.findOne(unitId)
    department = share.Department.findOne(team?.parentId || unitId)
    division = share.Division.findOne(department?.parentId || unitId)
    {
      team: team,
      department: department,
      division: division,
      unit: [team, department, division].find((unit) -> unit?)
    }
