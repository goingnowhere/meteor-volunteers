toShare = {}

toShare.getUserName  = AutoFormComponents.getUserName
toShare.getUserEmail = AutoFormComponents.getUserEmail

toShare.getOrgUnit = (unitId) =>
  team = share.Team.findOne(unitId)
  department = share.Department.findOne(team?.parentId || unitId)
  division = share.Division.findOne(department?.parentId || unitId)
  {
    team: team,
    department: department,
    division: division,
    lowest: [team, department, division].find((unit) => unit?)
  }

# waiting for this package to be fixed
@TAPi18n = { __: (n) -> n }

toShare.templateSub = (template,name,args...) ->
  template.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

toShare.meteorSub = (name,args...) ->
  Meteor.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

toShare.meteorCall = (name,args...) ->
  Meteor.call "#{share.eventName}.Volunteers.#{name}", args...

module.exports = toShare
_.extend(share, toShare)
