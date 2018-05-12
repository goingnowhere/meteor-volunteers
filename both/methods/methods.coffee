import SimpleSchema from 'simpl-schema'
import Moment from 'moment'
import { extendMoment } from 'moment-range'
moment = extendMoment(Moment)

throwError = (error, reason, details) ->
  error = new (Meteor.Error)(error, reason, details)
  if Meteor.isClient
    return error
  else if Meteor.isServer
    throw error
  return

doubleBooking = (shift,collectionKey) ->
  switch collectionKey
    when 'ShiftSignups'
      parentDoc = share.TeamShifts.findOne({_id: shift.shiftId})
      parentRange = moment.range(moment(parentDoc.start),moment(parentDoc.end))
      return _.chain(share.ShiftSignups.find({
        # it's a double booking only if it is a different shift
        shiftId: { $ne: shift.shiftId },
        userId: shift.userId,
        status: {$in: ["confirmed","pending"]}}).fetch())
        .map((shift) -> share.TeamShifts.findOne({_id: shift.shiftId}))
        .filter((shift) ->
          shiftRange = moment.range(moment(shift.start),moment(shift.end))
          parentRange.overlaps(shiftRange))
        .value()
    else
      return false

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
          if share.isManagerOrLead(Meteor.userId(),[Id])
            if Meteor.isServer then Roles.deleteRole(Id)
            collection.remove(Id)
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
          if share.isManagerOrLead(Meteor.userId(),allowedRoles)
            collection.insert(doc, (err,newDocId) ->
              unless err
                if Meteor.isServer
                  Roles.createRole(newDocId)
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
          if share.isManagerOrLead(Meteor.userId(),[doc._id])
            oldDoc = collection.findOne(doc._id)
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
  createDutiesMethod = (collection,type) ->
    collectionName = collection._name
    switch type
      when "remove"
        Meteor.methods "#{collectionName}.remove": (Id) ->
          console.log ["#{collectionName}.remove", Id]
          check(Id,String)
          doc = collection.findOne(Id)
          if share.isManagerOrLead(Meteor.userId(),[doc.parentId])
            collection.remove(Id)
          else
            throwError(403, 'Insufficient Permission')
      when "insert"
        Meteor.methods "#{collectionName}.insert": (doc) ->
          console.log ["#{collectionName}.insert",doc]
          collection.simpleSchema().validate(doc)
          if share.isManagerOrLead(Meteor.userId(),[doc.parentId])
            collection.insert(doc)
          else
            throwError(403, 'Insufficient Permission')
      when "update"
        Meteor.methods "#{collectionName}.update": (doc) ->
          console.log ["#{collectionName}.update",doc._id,doc.modifier]
          collection.simpleSchema().validate(doc.modifier,{modifier:true})
          olddoc = collection.findOne(doc._id)
          if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
            collection.update(doc._id,doc.modifier)
          else
            throwError(403, 'Insufficient Permission')
      when "updateGroup"
        Meteor.methods "#{collectionName}.group.update": (doc) ->
          console.log ["#{collectionName}.group.update",doc._id,doc.modifier]
          context = collection.simpleSchema()
            .omit('start', 'end', 'staffing', 'min', 'max', 'estimatedTime', 'dueDate')
            .validate(doc.modifier,{modifier:true})
          olddoc = collection.findOne(doc._id)
          if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
            collection.update(
              {parentId: olddoc.parentId, groupId: olddoc.groupId},
              doc.modifier,
              {multi: true},
            )
          else
            throwError(403, 'Insufficient Permission')
      else
        console.warn "type #{type} for #{collectionName} ERROR"

  createSignupMethod = (collectionKey, parentCollection, type) ->
    collection = share[collectionKey]
    schema = share.Schemas[collectionKey]
    collectionName = collection._name
    switch type
      when "remove"
        Meteor.methods "#{collectionName}.remove": (shiftId) ->
          console.log ["#{collectionName}.remove", shiftId]
          check(shiftId, String)
          olddoc = collection.findOne(shiftId)
          if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
            collection.remove(shiftId)
          else
            return throwError(403, 'Insufficient Permission')
      when "update"
        Meteor.methods "#{collectionName}.update": (doc) ->
          console.log ["#{collectionName}.update", doc]
          SimpleSchema.validate(doc.modifier, schema, { modifier: true })
          olddoc = collection.findOne(doc._id)
          if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
            collection.update(doc._id, doc.modifier)
          else
            return throwError(403, 'Insufficient Permission')
      when "insert"
        # this is actually an upsert
        Meteor.methods "#{collectionName}.insert": (doc) ->
          console.log ["#{collectionName}.insert", doc]
          SimpleSchema.validate(doc, schema.omit('status'))
          userId = Meteor.userId()
          # signup = _.omit(doc, 'status')
          signup = _.pick(doc,['userId','shiftId','parentId'])
          # signup.createdAt = new Date()
          parentDoc = parentCollection.findOne(signup.shiftId)
          if (signup.userId == userId) || (share.isManagerOrLead(userId,[parentDoc.parentId]))
            status =
              if parentDoc.policy == "public" then "confirmed"
              else if parentDoc.policy == "requireApproval" then "pending"
            { start, end } = doc
            if status
              # we can double booking only on new signups
              db = doubleBooking(signup,collectionKey)
              if db.length == 0
                if Meteor.isServer
                  res = collection.upsert(signup,{$set: {status,start,end}})
                  if res?.insertedId?
                    return res.insertedId
                  else
                    collection.findOne(signup)._id
              else
                return throwError(409, 'Double Booking', db)
          else
            return throwError(403, 'Insufficient Permission')
      when "bail"
        Meteor.methods "#{collectionName}.bail": (sel) ->
          console.log ["#{collectionName}.bail", sel]
          SimpleSchema.validate(sel, schema.omit('status','start','end'))
          userId = Meteor.userId()
          if (sel.userId == userId) || (share.isManagerOrLead(userId,[sel.parentId]))
            # multi : true just in case it is possible to singup for the same shift twice
            # this should not be possible. Failsafe !
            collection.update(sel, {$set: {status: "bailed"}}, {multi: true})
          else
            return throwError(403, 'Insufficient Permission')

  for type in ["remove","insert","update"]
    do ->
      for k,collection of share.orgUnitCollections
        do ->
          createOrgUnitMethod(collection, type)

  for type in ["remove","insert","update","updateGroup"]
    do ->
      for k,collection of share.dutiesCollections
        do ->
          createDutiesMethod(collection,type)

  for type in ['remove', 'update', 'insert', 'bail']
    do ->
      # XXX I think here we can do the same using share.dutiesCollections
      createSignupMethod('ShiftSignups', share.TeamShifts, type)
      createSignupMethod('TaskSignups', share.TeamTasks, type)
      createSignupMethod('ProjectSignups', share.Projects, type)

  prefix = "#{eventName}.Volunteers"

  Meteor.methods "#{prefix}.teamShifts.group.insert": (group) ->
    console.log ["#{prefix}.teamShifts.group.insert", group]
    share.Schemas.ShiftGroups.validate(group)
    {shifts, start, end} = group
    details = _.omit(group, 'shifts', 'start', 'end')
    if share.isManagerOrLead(Meteor.userId(),[group.parentId])
      groupId = Random.id()
      _.flatten(Array.from(moment.range(start, end).by('days')).map((day) ->
        shifts.map((shiftSpecifics) ->
          [startHour, startMin] = shiftSpecifics.startTime.split(':')
          [endHour, endMin] = shiftSpecifics.endTime.split(':')
          # this is the global timezone known by moment that we use to offset
          # the date given by the client to store it in the database as a js Date()
          # js Date() is timezone agnostic and always stored in UTC.
          # Using the method Date().toString() the local timezone (set on the server)
          # is used to print the date.
          timezone = moment().format('ZZ')
          day.utcOffset(timezone)
          shiftStart = moment(day).hour(startHour).minute(startMin).utcOffset(timezone, true)
          shiftEnd = moment(day).hour(endHour).minute(endMin).utcOffset(timezone, true)
          # Deal with day wrap-around
          if shiftEnd.isBefore(shiftStart)
            shiftEnd.add(1, 'day')
          return _.extend({
            min: shiftSpecifics.min,
            max: shiftSpecifics.max,
            start: shiftStart.toDate(),
            end: shiftEnd.toDate(),
            groupId,
          }, details))
        ), true).forEach((constructedShift) ->
          share.TeamShifts.insert(constructedShift)
        )
    else
      throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.volunteerForm.remove": (formId) ->
    console.log ["#{prefix}.volunteerForm.remove",formId]
    check(formId,String)
    if share.isManager()
      share.form.get().remove(formId)
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.volunteerForm.update": (doc) ->
    console.log ["#{prefix}.volunteerForm.update",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc.modifier,schema,{ modifier: true })
    oldDoc = share.form.get().findOne(doc._id)
    if (Meteor.userId() == oldDoc.userId) || share.isManager()
      share.form.get().update(doc._id,doc.modifier)
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.volunteerForm.insert": (doc) ->
    console.log ["#{prefix}.volunteerForm.insert",doc]
    schema = share.form.get().simpleSchema()
    SimpleSchema.validate(doc,schema)
    if Meteor.userId()
      doc.userId = Meteor.userId()
      share.form.get().insert(doc)
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.leadSignups.remove": (shiftId) ->
    console.log ["#{prefix}.leadSignups.remove",shiftId]
    check(shiftId,String)
    olddoc = share.LeadSignups.findOne(shiftId)
    if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
      share.LeadSignups.remove(shiftId, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Remove')
        )
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.leadSignups.confirm": (shiftId) ->
    console.log ["#{prefix}.leadSignups.confirm",shiftId]
    check(shiftId,String)
    olddoc = share.LeadSignups.findOne(shiftId)
    if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
      share.LeadSignups.update(shiftId, { $set: { status: 'confirmed' } }, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.addUsersToRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Update')
        )
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.leadSignups.refuse": (shiftId) ->
    console.log ["#{prefix}.leadSignups.refuse",shiftId]
    check(shiftId,String)
    olddoc = share.LeadSignups.findOne(shiftId)
    if share.isManagerOrLead(Meteor.userId(),[olddoc.parentId])
      share.LeadSignups.update(shiftId, { $set: { status: 'refused' } }, (err,res) ->
        unless err
          if Meteor.isServer
            Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Update')
        )
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.leadSignups.insert": (doc) ->
    console.log ["#{prefix}.leadSignups.insert",doc]
    SimpleSchema.validate(doc,share.Schemas.LeadSignups.omit('status'))
    userId = Meteor.userId()
    lead = share.Lead.findOne(doc.shiftId)
    if (doc.userId == userId) || (share.isManagerOrLead(userId,[lead.parentId]))
      doc.status =
        switch lead.policy
          when "public" then "confirmed"
          when "requireApproval" then "pending"
      if doc.status
        signup = _.pick(doc,['userId','shiftId','parentId'])
        # avoid to book the same shift twice
        if Meteor.isServer
          res = share.LeadSignups.upsert(signup, { $set: {status: doc.status} }, (err,res) ->
            unless err
              if lead.policy == "public"
                Roles.addUsersToRoles(doc.userId, lead.parentId, eventName)
            else
              return throwError(501, 'Cannot Insert')
          )
          # XXX we return an insertedId even if the function is called insert and should
          # return an simple id (or throw and error)
          if res?.insertedId?
            return res.insertedId
          else
            console.log share.LeadSignups.findOne(signup)
            share.LeadSignups.findOne(signup)._id
    else
      return throwError(403, 'Insufficient Permission')

  Meteor.methods "#{prefix}.leadSignups.bail": (sel) ->
    console.log ["#{prefix}.leadSignups.bail",sel]
    SimpleSchema.validate(sel,share.Schemas.LeadSignups.omit('status'))
    userId = Meteor.userId()
    olddoc = share.LeadSignups.findOne(sel)
    if (sel.userId == userId) || (share.isManagerOrLead(userId,[olddoc.parentId]))
      share.LeadSignups.update(sel,{$set: {status: "bailed"}},(err,res) ->
        unless err
          if Meteor.isServer
            Roles.removeUsersFromRoles(olddoc.userId, olddoc.parentId, eventName)
        else
          return throwError(501, 'Cannot Update')
        )
    else
      return throwError(403, 'Insufficient Permission')
