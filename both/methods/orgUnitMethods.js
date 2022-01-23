import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import { Roles } from 'meteor/alanning:roles'
import { collections } from '../collections/initCollections'
import { auth } from '../utils/auth'

function deleteUnitAndRoles(collection, id) {
  if (Meteor.isServer) {
    Roles.deleteRole(id)
  }
  collection.remove(id)
  // delete all shifts and signups associated to this team
  Object.values(collections.dutiesCollections).forEach(dutyColl => {
    dutyColl.remove({ parentId: id })
  })
  // WHY?
  // Object.values(collections.signupCollections).forEach(signupColl => {
  //   signupColl.update({ shiftId: id }, { $set: { status: 'cancelled' } })
  // })
  collections.signups.update({ shiftId: id }, { $set: { status: 'cancelled' } })
}

export function createOrgUnitMethods(collection) {
  const collectionName = collection._name
  return Meteor.methods({
    [`${collectionName}.remove`](id) {
      console.log(`${collectionName}.remove`, id)
      check(id, String)
      if (!auth.isLead(Meteor.userId(), [id])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      if (collectionName === collections.department._name) {
        collections.team.find({ parentId: id }).forEach(team => {
          deleteUnitAndRoles(collections.team, team._id)
        })
      }
      deleteUnitAndRoles(collection, id)
    },
    [`${collectionName}.insert`](doc) {
      console.log(`${collectionName}.insert`, doc)
      check(doc, Object)
      collection.simpleSchema().validate(doc)
      if (!auth.isLead(Meteor.userId(), ['manager', doc.parentId])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collection.insert(doc, (err, newDocId) => {
        if (err) {
          console.error(err)
          throw new Meteor.Error(501, 'Cannot Insert')
        }
        if (Meteor.isServer) {
          Roles.createRole(newDocId, { unlessExists: true })
          if (doc.parentId) Roles.addRolesToParent(newDocId, doc.parentId)
        }
      })
    },
    [`${collectionName}.update`](doc) {
      console.log(`${collectionName}.update`, doc._id, doc.modifier)
      check(doc, Object)
      collection.simpleSchema().validate(doc.modifier, { modifier: true })
      if (!auth.isLead(Meteor.userId(), [doc._id])) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      const oldDoc = collection.findOne(doc._id)
      if (!oldDoc) {
        throw new Meteor.Error(404)
      }
      return collection.update(doc._id, doc.modifier, (err) => {
        if (err) {
          console.error(err)
          throw new Meteor.Error(501, 'Cannot Update')
        }
        if (Meteor.isServer) {
          if (oldDoc.parentId !== doc.modifier.$set.parentId) {
            Roles.removeRolesFromParent(doc._id, oldDoc.parentId)
            Roles.addRolesToParent(doc._id, doc.modifier.$set.parentId)
          }
        }
      })
    },
  })
}
