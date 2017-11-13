import SimpleSchema from 'simpl-schema'

isRelevantLead = (userId, teamId) =>
  lead = share.Lead.findOne({ userId: userId })
  # This is a bit ugly but should be avoidable using roles
  return true if lead.parentId == teamId
  team = share.Team.findOne({ _id: teamId })
  return true if team.parentId == lead.parentId
  department = share.Department.findOne({ _id: team.parentId })
  department.parentId == lead.parentId

# Generic function to create insert,update,remove methods for groups within
# the organisation, e.g. teams
createOrgUnitMethod = (collection, type, parentCollection) ->
  collectionName = collection._name
  parentCollectionName = parentCollection?._name
  if type == "remove"
  #   Meteor.methods "#{collectionName}.remove": (Id) ->
  #     console.log ["#{collectionName}.remove", Id]
  #     check(Id,String)
  #     if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
  #       collection.remove(Id)
  else if type == "insert"
    Meteor.methods "#{collectionName}.insert": (doc) ->
      console.log ["#{collectionName}.insert",doc]
      collection.simpleSchema().namedContext().validate(doc)
      allowedRoles = [ 'manager' ]
      if doc.parentId != 'TopEntity'
        parentRole = "#{parentCollectionName}-#{doc.parentId}"
        allowedRoles.push(parentRole)
      if Roles.userIsInRole(Meteor.userId(), allowedRoles)
        insertResult = collection.insert(doc)
        unitRole = "#{collectionName}-#{insertResult}"
        Roles.createRole(unitRole)
        Roles.addRolesToParent(unitRole, parentRole) if parentRole?
  else if type == "update"
  #   Meteor.methods "#{collectionName}.update": (doc) ->
  #     console.log ["#{collectionName}.update",doc]
  #     collection.simpleSchema().namedContext().validate(doc.modifier,{modifier:true})
  #     if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
  #       collection.update(doc._id,doc.modifier)
  else
    console.warn "type #{type} for #{collectionName} ERROR"

# Generic function to create insert,update,remove methods.
# Security check : user must be manager
createMethod = (collection,type) ->
  collectioName = collection._name
  if type == "remove"
    Meteor.methods "#{collectioName}.remove": (Id) ->
      console.log ["#{collectioName}.remove", Id]
      check(Id,String)
      if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
        collection.remove(Id)
  else if type == "insert"
    Meteor.methods "#{collectioName}.insert": (doc) ->
      console.log ["#{collectioName}.insert",doc]
      collection.simpleSchema().namedContext().validate(doc)
      if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
        collection.insert(doc)
  else if type == "update"
    Meteor.methods "#{collectioName}.update": (doc) ->
      console.log ["#{collectioName}.update",doc]
      collection.simpleSchema().namedContext().validate(doc.modifier,{modifier:true})
      if Roles.userIsInRole(Meteor.userId(), [ 'manager' ])
        collection.update(doc._id,doc.modifier)
  else
    console.warn "type #{type} for #{collectioName} ERROR"

share.initMethods = (eventName) ->
  # Must be in descending hierarchical order
  orgUnitCollections = [
    share.Division,
    share.Department,
    share.Team,
  ]
  normalCollections = [
    share.Lead,
    share.TeamShifts,
    share.TeamTasks
  ]
  for type in ["remove","insert","update"]
    do ->
      for collection, index in orgUnitCollections
        do =>
          createOrgUnitMethod(collection, type, orgUnitCollections[index - 1])
      for collection in normalCollections
        do ->
          createMethod(collection,type)

  prefix = "#{eventName}.Volunteers"
  Meteor.methods "#{prefix}.volunteerForm.remove": (formId) ->
    console.log ["#{prefix}.volunteerForm.remove",formId]
    check(formId,String)
    userId = Meteor.userId()
    if Roles.userIsInRole(userId, [ 'manager' ])
      share.form.get().remove(formId)

  Meteor.methods "#{prefix}.volunteerForm.update": (doc) ->
    console.log ["#{prefix}.volunteerForm.update",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc.modifier,schema,{ modifier: true })
    userId = Meteor.userId()
    if (userId == doc.userId) || Roles.userIsInRole(userId, [ 'manager' ])
      share.form.get().update(doc._id,doc.modifier)

  Meteor.methods "#{prefix}.volunteerForm.insert": (doc) ->
    console.log ["#{prefix}.volunteerForm.insert",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc,schema)
    if Meteor.userId()
      doc.userId = Meteor.userId()
      share.form.get().insert(doc)

  Meteor.methods "#{prefix}.shiftSignups.remove": (shiftId) ->
    console.log ["#{prefix}.shiftSignups.remove",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.ShiftSignups.findOne(shiftId)
    if (olddoc.userId == userId) || Roles.userIsInRole(userId, [ 'manager' ])
      share.ShiftSignups.remove(shiftId)

  Meteor.methods "#{prefix}.shiftSignups.update": (doc) ->
    console.log ["#{prefix}.shiftSignups.update",doc]
    SimpleSchema.validate(doc.modifier,share.Schemas.ShiftSignups,{ modifier: true })
    userId = Meteor.userId()
    olddoc = share.ShiftSignups.findOne(doc._id)
    if Roles.userIsInRole(userId, [ 'manager' ]) || isRelevantLead(userId, olddoc.teamId)
      share.ShiftSignups.update(doc._id, doc.modifier)

  Meteor.methods "#{prefix}.shiftSignups.insert": (doc) ->
    console.log ["#{prefix}.shiftSignups.insert",doc]
    SimpleSchema.validate(doc,share.Schemas.ShiftSignups.omit('status'))
    userId = Meteor.userId()
    if (doc.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
      teamShift = share.TeamShifts.findOne(doc.shiftId)
      status = (
        if teamShift.policy == "public" then "confirmed"
        else if teamShift.policy == "requireApproval" then "pending")
      if status
        if Meteor.isServer
          share.ShiftSignups.upsert(doc, {$set : {status: status }})

  Meteor.methods "#{prefix}.shiftSignups.bail": (sel) ->
    console.log ["#{prefix}.shiftSignups.bail",sel]
    SimpleSchema.validate(sel,share.Schemas.ShiftSignups.omit('status'))
    userId = Meteor.userId()
    if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
      share.ShiftSignups.update(sel,{$set: {status: "bailed"}})

  Meteor.methods "#{prefix}.taskSignups.remove": (shiftId) ->
    console.log ["#{prefix}.taskSignups.remove",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.TaskSignups.findOne(shiftId)
    if (olddoc.userId == userId) || Roles.userIsInRole(userId, [ 'manager' ])
      share.TaskSignups.remove(shiftId)

  Meteor.methods "#{prefix}.taskSignups.update": (doc) ->
    console.log ["#{prefix}.taskSignups.update",doc]
    SimpleSchema.validate(doc.modifier,share.Schemas.TaskSignups,{ modifier: true })
    userId = Meteor.userId()
    olddoc = share.TaskSignups.findOne(doc._id)
    if Roles.userIsInRole(userId, [ 'manager' ]) || isRelevantLead(userId, olddoc.teamId)
      share.TaskSignups.update(doc._id, doc.modifier)

  Meteor.methods "#{prefix}.taskSignups.insert": (doc) ->
    console.log ["#{prefix}.taskSignups.insert",doc]
    SimpleSchema.validate(doc,share.Schemas.TaskSignups.omit('status'))
    userId = Meteor.userId()
    if (doc.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
      teamTask = share.TeamTasks.findOne(doc.shiftId)
      status = (
        if teamTask.policy == "public" then "confirmed"
        else if teamTask.policy == "requireApproval" then "pending")
      if status
        doc.status = status
        share.TaskSignups.insert(doc)

  Meteor.methods "#{prefix}.taskSignups.bail": (sel) ->
    console.log ["#{prefix}.taskSignups.bail",sel]
    SimpleSchema.validate(sel,share.Schemas.TaskSignups.omit('status'))
    userId = Meteor.userId()
    if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager' ]))
      share.TaskSignups.update(sel,{$set: {status: "bailed"}})
