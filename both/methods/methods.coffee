import SimpleSchema from 'simpl-schema'
import { collections } from '../collections/initCollections'
import { auth } from '../utils/auth'

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
    switch type
      when "remove"
        Meteor.methods "#{collectionName}.remove": (Id) ->
          console.log ["#{collectionName}.remove", Id]
          check(Id,String)
          if auth.isLead(Meteor.userId(),[Id])
            if Meteor.isServer then Roles.deleteRole(Id)
            collection.remove(Id)
            # delete all shifts and signups associated to this team
            # XXX if this is a dept, we should remove also all teams
            for k,collection of collections.dutiesCollections
              do ->
                collection.remove({parentId: Id})
            for k,collection of collections.signupCollections
              do ->
                collection.update({shiftId: Id},{$set: {status: 'cancelled'}})
          else
            return throwError(403, 'Insufficient Permission')
      when "insert"
        Meteor.methods "#{collectionName}.insert": (doc) ->
          console.log ["#{collectionName}.insert",doc]
          collection.simpleSchema().validate(doc)
          allowedRoles = [ 'manager' ]
          if doc.parentId != 'TopEntity'
            parentRole = doc.parentId
            allowedRoles.push(parentRole)
          if auth.isLead(Meteor.userId(),allowedRoles)
            collection.insert(doc, (err,newDocId) ->
              unless err
                if Meteor.isServer
                  Roles.createRole(newDocId, {unlessExists: true})
                  Roles.addRolesToParent(newDocId, parentRole) if parentRole?
              else
                return throwError(501, 'Cannot Insert')
              )
          else
            return throwError(403, 'Insufficient Permission')
      when "update"
        Meteor.methods "#{collectionName}.update": (doc) ->
          console.log ["#{collectionName}.update",doc._id,doc.modifier]
          collection.simpleSchema().validate(doc.modifier,{modifier:true})
          if auth.isLead(Meteor.userId(),[doc._id])
            oldDoc = collection.findOne(doc._id)
            unless oldDoc
              return throwError(404)
            collection.update(doc._id,doc.modifier, (err,res) ->
              unless err
                if Meteor.isServer
                  if oldDoc.parentId != doc.modifier.$set.parentId
                    Roles.removeRolesFromParent(doc._id, oldDoc.parentId)
                    Roles.addRolesToParent(doc._id, doc.modifier.$set.parentId)
              else
                return throwError(501, 'Cannot Update')
              )
          else
            return throwError(403, 'Insufficient Permission')
      else
        console.warn "type #{type} for #{collectionName} ERROR"

  # Generic function to create insert,update,remove methods.
  # Security check : user must be manager
  createDutiesMethod = (collection,type,kind) ->
    collectionName = collection._name
    switch type
      when "remove"
        Meteor.methods "#{collectionName}.remove": (Id) ->
          console.log ["#{collectionName}.remove", Id]
          check(Id,String)
          doc = collection.findOne(Id)
          if auth.isLead(Meteor.userId(),[doc.parentId])
            collection.remove(Id)
            for k,scollection of collections.signupCollections
              do ->
                scollection.update({shiftId: Id},{$set: {status: 'cancelled'}})
          else
            throwError(403, 'Insufficient Permission')
      when "insert"
        Meteor.methods "#{collectionName}.insert": (doc) ->
          console.log ["#{collectionName}.insert",doc]
          collection.simpleSchema().validate(doc)
          if auth.isLead(Meteor.userId(),[doc.parentId])
            collection.insert(doc)
          else
            throwError(403, 'Insufficient Permission')
      when "update"
        Meteor.methods "#{collectionName}.update": (doc) ->
          console.log ["#{collectionName}.update",doc._id,doc.modifier]
          collection.simpleSchema().validate(doc.modifier,{modifier:true})
          olddoc = collection.findOne(doc._id)
          if auth.isLead(Meteor.userId(),[olddoc.parentId])
            collection.update(doc._id,doc.modifier)
          else
            throwError(403, 'Insufficient Permission')
      else
        console.warn "type #{type} for #{collectionName} ERROR"

  for type in ["remove","insert","update"]
    do ->
      for kind,collection of collections.dutiesCollections
        do ->
          createDutiesMethod(collection,type, kind)

  for type in ["remove","insert","update"]
    do ->
      for kind,collection of collections.orgUnitCollections
        do ->
          createOrgUnitMethod(collection, type, kind)

  prefix = "#{eventName}.Volunteers"

  Meteor.methods "#{prefix}.volunteerForm.remove": (formId) ->
    console.log ["#{prefix}.volunteerForm.remove",formId]
    check(formId,String)
    if auth.isManager()
      share.VolunteerForm.remove(formId)
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.volunteerForm.update": (doc) ->
    console.log ["#{prefix}.volunteerForm.update",doc]
    schema = share.VolunteerForm.simpleSchema()
    SimpleSchema.validate(doc.modifier,schema,{ modifier: true })
    oldDoc = share.VolunteerForm.findOne(doc._id)
    if (Meteor.userId() == oldDoc.userId) || auth.isManager()
      share.VolunteerForm.update(doc._id,doc.modifier)
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.volunteerForm.insert": (doc) ->
    console.log ["#{prefix}.volunteerForm.insert",doc]
    schema = share.VolunteerForm.simpleSchema()
    SimpleSchema.validate(doc,schema)
    if Meteor.userId()
      doc.userId = Meteor.userId()
      share.VolunteerForm.insert(doc)
    else
      return throwError(403, 'Insufficient Permission')
