share.getUserName  = AutoFormComponents.getUserName
share.getUserEmail = AutoFormComponents.getUserEmail

# waiting for this package to be fixed
@TAPi18n = { __: (n) -> n }

share.templateSub = (template,name,args...) ->
  template.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

share.meteorSub = (name,args...) ->
  Meteor.subscribe("#{share.eventName}.Volunteers.#{name}",args...)

share.meteorCall = (name,args...) ->
  Meteor.call "#{share.eventName}.Volunteers.#{name}", args...
