import SimpleSchema from 'simpl-schema'

checkForCollisions = (shift) ->
  share.taskSignups.findOne({
    userId: shift.userId,
    start: { $leq: shift.start },
    end: { $geq: shift.end }})?

toShare = {}
toShare.initMethods = (eventName) ->
  # Generic function to create insert,update,remove methods for groups within
  # the organisation, e.g. teams
  createOrgUnitMethod = (collection, type) ->
    collectionName = collection._name
    if type == "remove"
      Meteor.methods "#{collectionName}.remove": (Id) ->
        console.log ["#{collectionName}.remove", Id]
        check(Id,String)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', Id ], eventName)
          Roles.deleteRole(Id)
          collection.remove(Id)
    else if type == "insert"
      Meteor.methods "#{collectionName}.insert": (doc) ->
        console.log ["#{collectionName}.insert",doc]
        collection.simpleSchema().namedContext().validate(doc)
        allowedRoles = [ 'manager' ]
        if doc.parentId != 'TopEntity'
          parentRole = doc.parentId
          allowedRoles.push(parentRole)
        if Roles.userIsInRole(Meteor.userId(), allowedRoles, eventName)
          insertResult = collection.insert(doc)
          Roles.createRole(insertResult)
          Roles.addRolesToParent(insertResult, parentRole) if parentRole?
    else if type == "update"
      Meteor.methods "#{collectionName}.update": (doc) ->
        console.log ["#{collectionName}.update",doc]
        collection.simpleSchema().namedContext().validate(doc.modifier,{modifier:true})
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', doc._id ], eventName)
          updatedParentId = doc.modifier.parentId || doc.modifier.$set?.updatedParentId
          if updatedParentId?
            oldDoc = collection.findOne(doc._id)
            Roles.removeRolesFromParent(doc._id, oldDoc.parentId)
            Roles.addRolesToParent(doc._id, updatedParentId)
          collection.update(doc._id,doc.modifier)
    else
      console.warn "type #{type} for #{collectionName} ERROR"

  # Generic function to create insert,update,remove methods.
  # Security check : user must be manager
  createMethod = (collection,type) ->
    collectionName = collection._name
    if type == "remove"
      Meteor.methods "#{collectionName}.remove": (Id) ->
        console.log ["#{collectionName}.remove", Id]
        check(Id,String)
        doc = collection.findOne(Id)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', doc.parentId ], eventName)
          collection.remove(Id)
    else if type == "insert"
      Meteor.methods "#{collectionName}.insert": (doc) ->
        console.log ["#{collectionName}.insert",doc]
        collection.simpleSchema().namedContext().validate(doc)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', doc.parentId ], eventName)
          collection.insert(doc)
    else if type == "update"
      Meteor.methods "#{collectionName}.update": (doc) ->
        console.log ["#{collectionName}.update",doc]
        collection.simpleSchema().namedContext().validate(doc.modifier,{modifier:true})
        olddoc = collection.findOne(doc._id)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', olddoc.parentId ], eventName)
          collection.update(doc._id,doc.modifier)
    else
      console.warn "type #{type} for #{collectionName} ERROR"

  createSignupMethod = (collectionKey, parentCollection, type) =>
    collection = share[collectionKey]
    schema = share.Schemas[collectionKey]
    collectionName = collection._name
    if type == "remove"
      Meteor.methods "#{collectionName}.remove": (shiftId) ->
        console.log ["#{collectionName}.remove", shiftId]
        check(shiftId, String)
        userId = Meteor.userId()
        olddoc = collection.findOne(shiftId)
        if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
          collection.remove(shiftId)
    else if type == "update"
      Meteor.methods "#{collectionName}.update": (doc) ->
        console.log ["#{collectionName}.update", doc]
        SimpleSchema.validate(doc.modifier, schema, { modifier: true })
        userId = Meteor.userId()
        olddoc = collection.findOne(doc._id)
        if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
          collection.update(doc._id, doc.modifier)
    else if type == "insert"
      Meteor.methods "#{collectionName}.insert": (doc) ->
        console.log ["#{collectionName}.insert", doc]
        SimpleSchema.validate(doc, schema.omit('status'))
        userId = Meteor.userId()
        parentDoc = parentCollection.findOne(doc.shiftId)
        if (doc.userId == userId) ||
            (Roles.userIsInRole(userId, [ 'manager', parentDoc.parentId ], eventName))
          doc.status = (
            if parentDoc.policy == "public" then "confirmed"
            else if parentDoc.policy == "requireApproval" then "pending")
          if doc.status
            collection.insert(doc)
    else if type == "bail"
      Meteor.methods "#{collectionName}.bail": (sel) ->
        console.log ["#{collectionName}.bail", sel]
        SimpleSchema.validate(sel, schema.omit('status'))
        userId = Meteor.userId()
        if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager', sel.parentId ], eventName))
          collection.update(sel, {$set: {status: "bailed"}})

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
      for collection in orgUnitCollections
        do =>
          createOrgUnitMethod(collection, type)
      for collection in normalCollections
        do ->
          createMethod(collection,type)

  for type in ['remove', 'update', 'insert', 'bail']
    do =>
      createSignupMethod('ShiftSignups', share.TeamShifts, type)
      createSignupMethod('TaskSignups', share.TeamTasks, type)

  prefix = "#{eventName}.Volunteers"
  Meteor.methods "#{prefix}.volunteerForm.remove": (formId) ->
    console.log ["#{prefix}.volunteerForm.remove",formId]
    check(formId,String)
    userId = Meteor.userId()
    if Roles.userIsInRole(userId, [ 'manager' ], eventName)
      share.form.get().remove(formId)

  Meteor.methods "#{prefix}.volunteerForm.update": (doc) ->
    console.log ["#{prefix}.volunteerForm.update",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc.modifier,schema,{ modifier: true })
    userId = Meteor.userId()
    if (userId == doc.userId) || Roles.userIsInRole(userId, [ 'manager' ], eventName)
      share.form.get().update(doc._id,doc.modifier)

  Meteor.methods "#{prefix}.volunteerForm.insert": (doc) ->
    console.log ["#{prefix}.volunteerForm.insert",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc,schema)
    if Meteor.userId()
      doc.userId = Meteor.userId()
      share.form.get().insert(doc)

  Meteor.methods "#{prefix}.leadSignups.remove": (shiftId) ->
    console.log ["#{prefix}.leadSignups.remove",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(shiftId)
    if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
      Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
      share.LeadSignups.remove(shiftId)

  Meteor.methods "#{prefix}.leadSignups.confirm": (shiftId) ->
    console.log ["#{prefix}.leadSignups.confirm",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(shiftId)
    if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
      Roles.addUsersToRoles(olddoc.userId, olddoc.parentId, eventName)
      share.LeadSignups.update(shiftId, { $set: { status: 'confirmed' } })

  Meteor.methods "#{prefix}.leadSignups.refuse": (shiftId) ->
    console.log ["#{prefix}.leadSignups.refuse",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(shiftId)
    if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
      Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
      share.LeadSignups.update(shiftId, { $set: { status: 'refused' } })

  Meteor.methods "#{prefix}.leadSignups.insert": (doc) ->
    console.log ["#{prefix}.leadSignups.insert",doc]
    SimpleSchema.validate(doc,share.Schemas.LeadSignups.omit('status'))
    userId = Meteor.userId()
    lead = share.Lead.findOne(doc.shiftId)
    if (doc.userId == userId) ||
        (Roles.userIsInRole(userId, [ 'manager', lead.parentId ], eventName))
      if lead.policy == "public"
        doc.status = "confirmed"
        Roles.addUsersToRoles(doc.userId, lead.parentId, eventName)
      if lead.policy == "requireApproval"
        doc.status = "pending"
      if doc.status
        share.LeadSignups.insert(doc)

  Meteor.methods "#{prefix}.leadSignups.bail": (sel) ->
    console.log ["#{prefix}.leadSignups.bail",sel]
    SimpleSchema.validate(sel,share.Schemas.LeadSignups.omit('status'))
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(sel._id)
    if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName))
      Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
      share.LeadSignups.update(sel,{$set: {status: "bailed"}})

module.exports = toShare
_.extend(share, toShare)
