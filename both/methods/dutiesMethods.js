import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import { collections } from '../collections/initCollections'
import { auth } from '../utils/auth'

export function createDutiesMethod(collection) {
  const collectionName = collection._name
  Meteor.methods({
    [`${collectionName}.remove`](id) {
      console.log(`${collectionName}.remove`, id)
      check(id, String)
      const doc = collection.findOne(id)
      if (!auth.isLead(Meteor.userId(), doc.parentId)) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      collection.remove(id)
      collections.signups.update({ shiftId: id }, { $set: { status: 'cancelled' } })
    },
    [`${collectionName}.insert`](doc) {
      console.log([`${collectionName}.insert`, doc])
      check(doc, Object)
      collection.simpleSchema().validate(doc)
      if (!auth.isLead(Meteor.userId(), doc.parentId)) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collection.insert(doc)
    },
    [`${collectionName}.update`](doc) {
      console.log([`${collectionName}.update`, doc._id, doc.modifier])
      check(doc, Object)
      collection.simpleSchema().validate(doc.modifier, { modifier: true })
      const olddoc = collection.findOne(doc._id)
      if (!this.isSimulation && !auth.isLead(Meteor.userId(), olddoc.parentId)) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collection.update(doc._id, doc.modifier)
    },
  })
}
