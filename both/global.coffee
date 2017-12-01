toShare = {}

toShare.getUserName  = AutoFormComponents.getUserName
toShare.getUserEmail = AutoFormComponents.getUserEmail

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
