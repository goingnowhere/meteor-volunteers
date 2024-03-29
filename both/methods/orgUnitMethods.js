import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import { Roles } from 'meteor/alanning:roles'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

export function initOrgUnitMethods(volunteersClass) {
  const { collections, eventName, services: { auth } } = volunteersClass

  function deleteUnitAndRoles(collection, id) {
    if (Meteor.isServer) {
      Roles.deleteRole(id)
    }
    collection.remove(id)
    // delete all shifts and signups associated to this team
    Object.values(collections.dutiesCollections).forEach(dutyColl => {
      dutyColl.remove({ parentId: id })
    })
    collections.signups.update({ shiftId: id }, { $set: { status: 'cancelled' } })
  }

  function createOrgUnitMethods(collection) {
    const collectionName = collection._name
    return Meteor.methods({
      [`${collectionName}.remove`](id) {
        console.log(`${collectionName}.remove`, id)
        check(id, String)
        if (!auth.isLead(Meteor.userId(), id)) {
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
        if (!auth.isLead(Meteor.userId(), doc.parentId)) {
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
        if (!auth.isLead(Meteor.userId(), doc._id)) {
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

  // Actually create the methods (nothing to return as they're not 'ValidatedMethod's)
  Object.values(collections.orgUnitCollections).forEach(orgUnitColl => {
    createOrgUnitMethods(orgUnitColl)
  })

  return {
    addRoleToUser: new ValidatedMethod({
      name: 'user.role.add',
      validate: ({ userId, role }) => check(role, String) && check(userId, String),
      mixins: [auth.mixins.isManager],
      run({ userId, role }) {
        if (Meteor.isServer) {
          const allowedRoles = Roles.userIsInRole(Meteor.userId(), 'admin', eventName)
            ? ['admin', 'manager'] : ['manager']
          if (!allowedRoles.includes(role)) {
            throw new Meteor.Error(403,
              `You don't have adequate permissions to make a user a ${role}`)
          }
          Roles.addUsersToRoles(userId, role, eventName)
        }
      },
    }),
    removeRoleFromUser: new ValidatedMethod({
      name: 'user.role.remove',
      validate: ({ userId, role }) => check(role, String) && check(userId, String),
      mixins: [auth.mixins.isManager],
      run({ userId, role }) {
        if (Meteor.isServer) {
          const allowedRoles = Roles.userIsInRole(Meteor.userId(), 'admin', eventName)
            ? ['admin', 'manager'] : ['manager']
          if (!allowedRoles.includes(role)) {
            throw new Meteor.Error(403,
            `You don't have adequate permissions to remove ${role} from a user`)
          }
          Roles.removeUsersFromRoles(userId, role, eventName)
        }
      },
    }),
  }
}
