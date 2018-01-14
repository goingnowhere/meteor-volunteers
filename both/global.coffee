share.getUserName  = AutoFormComponents.getUserName
share.getUserEmail = AutoFormComponents.getUserEmail

# waiting for this package to be fixed
@TAPi18n = { __: (n) -> n }

share.templateSub = (template,name,args...) ->
  template.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

share.meteorSub = (name,args...) ->
  Meteor.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

share.meteorCall = (name,args...) ->
  Meteor.call("#{share.eventName}.Volunteers.#{name}", args... , (err,res) ->
    console.log(err);
    if err
      Bert.alert({
        title: 'Now Playing',
        message: err,
        type: 'info',
        style: 'growl-top-right',
        icon: 'fa-music'
      })
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
      unit: [team, department, division].find((unit) => unit?)
    }
