import { Meteor } from 'meteor/meteor'
import { check } from 'meteor/check'
import SimpleSchema from 'simpl-schema'

export function initVolunteerformMethods(volunteersClass) {
  const { collections, eventName, services: { auth } } = volunteersClass
  const prefix = `${eventName}.Volunteers`

  Meteor.methods({
    [`${prefix}.volunteerForm.remove`](formId) {
      console.log(`${prefix}.volunteerForm.remove`, formId)
      check(formId, String)
      if (!auth.isManager()) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collections.volunteerForm.remove(formId)
    },
    [`${prefix}.volunteerForm.update`](doc) {
      console.log(`${prefix}.volunteerForm.update`, doc)
      check(doc, Object)
      const schema = collections.volunteerForm.simpleSchema()
      SimpleSchema.validate(doc.modifier, schema, { modifier: true })
      const oldDoc = collections.volunteerForm.findOne(doc._id)
      if ((Meteor.userId() !== oldDoc.userId) && !auth.isManager()) {
        throw new Meteor.Error(403, 'Insufficient Permission')
      }
      return collections.volunteerForm.update(doc._id, doc.modifier)
    },
    [`${prefix}.volunteerForm.insert`](doc) {
      console.log(`${prefix}.volunteerForm.insert`, doc)
      check(doc, Object)
      const schema = collections.volunteerForm.simpleSchema()
      SimpleSchema.validate(doc, schema)
      if (!Meteor.userId()) {
        throw new Meteor.Error(401, 'Not logged in')
      }
      doc.userId = Meteor.userId()
      return collections.volunteerForm.insert(doc)
    },
  })
}
