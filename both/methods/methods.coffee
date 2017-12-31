import SimpleSchema from 'simpl-schema'

throwError = (error, reason, details) ->
  error = new (Meteor.Error)(error, reason, details)
  if Meteor.isClient
    return error
  else if Meteor.isServer
    throw error
  return

share.initMethods = (eventName) ->
  # Generic function to create insert,update,remove methods for groups within
  # the organisation, e.g. teams
  createOrgUnitMethod = (collection, type) ->
    collectionName = collection._name
    if type == "remove"
      Meteor.methods "#{collectionName}.remove": (Id) ->
        console.log ["#{collectionName}.remove", Id]
        check(Id,String)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', Id ], eventName)
          if Meteor.isServer then Roles.deleteRole(Id)
          collection.remove(Id)
        else
          return throwError(403, 'Insufficient Permission');
    else if type == "insert"
      Meteor.methods "#{collectionName}.insert": (doc) ->
        console.log ["#{collectionName}.insert",doc]
        collection.simpleSchema().namedContext().validate(doc)
        allowedRoles = [ 'manager' ]
        if doc.parentId != 'TopEntity'
          parentRole = doc.parentId
          allowedRoles.push(parentRole)
        if Roles.userIsInRole(Meteor.userId(), allowedRoles, eventName)
          collection.insert(doc, (err,newDocId) ->
            unless err
              if Meteor.isServer
                Roles.createRole(newDocId)
                Roles.addRolesToParent(newDocId, parentRole) if parentRole?
            else
              return throwError(501, 'Cannot Insert');
            )
        else
          return throwError(403, 'Insufficient Permission');
    else if type == "update"
      Meteor.methods "#{collectionName}.update": (doc) ->
        console.log ["#{collectionName}.update",doc.modifier]
        collection.simpleSchema().namedContext().validate(doc.modifier,{modifier:true})
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', doc._id ], eventName)
          oldDoc = collection.findOne(doc._id)
          collection.update(doc._id,doc.modifier, (err,res) ->
            unless err
              if Meteor.isServer
                if oldDoc.parentId != doc.modifier.$set.parentId
                  Roles.removeRolesFromParent(doc._id, oldDoc.parentId)
                  Roles.addRolesToParent(doc._id, doc.modifier.$set.parentId)
            else
              return throwError(501, 'Cannot Update');
            )
        else
          return throwError(403, 'Insufficient Permission');
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
        else
          throwError(403, 'Insufficient Permission')
    else if type == "insert"
      Meteor.methods "#{collectionName}.insert": (doc) ->
        console.log ["#{collectionName}.insert",doc]
        collection.simpleSchema().namedContext().validate(doc)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', doc.parentId ], eventName)
          collection.insert(doc)
        else
          throwError(403, 'Insufficient Permission')
    else if type == "update"
      Meteor.methods "#{collectionName}.update": (doc) ->
        console.log ["#{collectionName}.update",doc]
        collection.simpleSchema().namedContext().validate(doc.modifier,{modifier:true})
        olddoc = collection.findOne(doc._id)
        if Roles.userIsInRole(Meteor.userId(), [ 'manager', olddoc.parentId ], eventName)
          collection.update(doc._id,doc.modifier)
        else
          throwError(403, 'Insufficient Permission')
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
        else
          return throwError(403, 'Insufficient Permission');
    else if type == "update"
      Meteor.methods "#{collectionName}.update": (doc) ->
        console.log ["#{collectionName}.update", doc]
        SimpleSchema.validate(doc.modifier, schema, { modifier: true })
        userId = Meteor.userId()
        olddoc = collection.findOne(doc._id)
        if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
          collection.update(doc._id, doc.modifier)
        else
          return throwError(403, 'Insufficient Permission');
    else if type == "insert"
      Meteor.methods "#{collectionName}.insert": (doc) ->
        console.log ["#{collectionName}.insert", doc]
        SimpleSchema.validate(doc, schema.omit('status'))
        userId = Meteor.userId()
        parentDoc = parentCollection.findOne(doc.shiftId)
        # XXX In this case only the manager or the lead of the team can add a
        # volunteer to a shift. Can the lead of a Department add a volunteer to
        # of a team of its Department ? .
        if (doc.userId == userId) ||
            (Roles.userIsInRole(userId, [ 'manager', parentDoc.parentId ], eventName))
          doc.status =
            if parentDoc.policy == "public" then "confirmed"
            else if parentDoc.policy == "requireApproval" then "pending"
          if doc.status
            collection.insert(doc)
        else
          return throwError(403, 'Insufficient Permission');
    else if type == "bail"
      Meteor.methods "#{collectionName}.bail": (sel) ->
        console.log ["#{collectionName}.bail", sel]
        SimpleSchema.validate(sel, schema.omit('status'))
        userId = Meteor.userId()
        if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager', sel.parentId ], eventName))
          collection.update(sel, {$set: {status: "bailed"}})
        else
          return throwError(403, 'Insufficient Permission');

  for type in ["remove","insert","update"]
    do ->
      for k,collection of share.orgUnitCollections
        do ->
          createOrgUnitMethod(collection, type)
      for k,collection of share.dutiesCollections
        do ->
          createMethod(collection,type)

  for type in ['remove', 'update', 'insert', 'bail']
    do ->
      # XXX I think here we can do the same using share.dutiesCollections
      createSignupMethod('ShiftSignups', share.TeamShifts, type)
      createSignupMethod('TaskSignups', share.TeamTasks, type)

  prefix = "#{eventName}.Volunteers"
  Meteor.methods "#{prefix}.volunteerForm.remove": (formId) ->
    console.log ["#{prefix}.volunteerForm.remove",formId]
    check(formId,String)
    userId = Meteor.userId()
    if Roles.userIsInRole(userId, [ 'manager' ], eventName)
      share.form.get().remove(formId)
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.volunteerForm.update": (doc) ->
    console.log ["#{prefix}.volunteerForm.update",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc.modifier,schema,{ modifier: true })
    userId = Meteor.userId()
    if (userId == doc.userId) || Roles.userIsInRole(userId, [ 'manager' ], eventName)
      share.form.get().update(doc._id,doc.modifier)
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.volunteerForm.insert": (doc) ->
    console.log ["#{prefix}.volunteerForm.insert",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc,schema)
    if Meteor.userId()
      doc.userId = Meteor.userId()
      share.form.get().insert(doc)
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.leadSignups.remove": (shiftId) ->
    console.log ["#{prefix}.leadSignups.remove",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(shiftId)
    if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
      share.LeadSignups.remove(shiftId, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Remove');
        )
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.leadSignups.confirm": (shiftId) ->
    console.log ["#{prefix}.leadSignups.confirm",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(shiftId)
    if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
      share.LeadSignups.update(shiftId, { $set: { status: 'confirmed' } }, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.addUsersToRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Update');
        )
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.leadSignups.refuse": (shiftId) ->
    console.log ["#{prefix}.leadSignups.refuse",shiftId]
    check(shiftId,String)
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(shiftId)
    if Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName)
      share.LeadSignups.update(shiftId, { $set: { status: 'refused' } }, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Update');
        )
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.leadSignups.insert": (doc) ->
    console.log ["#{prefix}.leadSignups.insert",doc]
    SimpleSchema.validate(doc,share.Schemas.LeadSignups.omit('status'))
    userId = Meteor.userId()
    lead = share.Lead.findOne(doc.shiftId)
    if (doc.userId == userId) ||
        (Roles.userIsInRole(userId, [ 'manager', lead.parentId ], eventName))
      if lead.policy == "public"
        doc.status = "confirmed"
      if lead.policy == "requireApproval"
        doc.status = "pending"
      if doc.status
        share.LeadSignups.insert(doc, (err,res) ->
          unless err
            if Meteor.isServer
              Roles.addUsersToRoles(doc.userId, lead.parentId, eventName)
          else
            return throwError(501, 'Cannot Insert');
          )
    else
      return throwError(403, 'Insufficient Permission');

  Meteor.methods "#{prefix}.leadSignups.bail": (sel) ->
    console.log ["#{prefix}.leadSignups.bail",sel]
    SimpleSchema.validate(sel,share.Schemas.LeadSignups.omit('status'))
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(sel._id)
    if (sel.userId == userId) || (Roles.userIsInRole(userId, [ 'manager', olddoc.parentId ], eventName))
      share.LeadSignups.update(sel,{$set: {status: "bailed"}}, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Update');
        )
    else
      return throwError(403, 'Insufficient Permission');
