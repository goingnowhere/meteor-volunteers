import { Mongo } from 'meteor/mongo'
import { rawCollectionOp } from 'meteor/goingnowhere:volunteers'
import SimpleSchema from 'simpl-schema'
import moment from 'moment-timezone'

const queueSchema = new SimpleSchema({
  createdAt: {
    type: Date,
    autoValue() {
      if (this.isInsert) return new Date()
      return this.unset()
    },
  },
  lock: {
    type: Date,
    optional: true,
  },
  // TODO could pass this in to enforce correct structure
  data: {
    type: Object,
  },
})

export class MongoBackedQueue {
  name

  queue

  constructor(name) {
    this.name = name
    this.queue = new Mongo.Collection(`queue.${name}`)
    this.queue.attachSchema(queueSchema)
  }

  addToQueue(items) {
    const createdAt = new Date()
    rawCollectionOp(this.queue, 'insertMany', items.map((data) => ({ data, createdAt })))
  }

  processItem(process) {
    const lockExpiry = moment().subtract(1, 'hours').toDate()
    let itemId
    try {
      // Find and lock
      const findResult = rawCollectionOp(
        this.queue,
        'findOneAndUpdate',
        { $or: [{ lock: { $lt: lockExpiry } }, { lock: { $exists: false } }] },
        { $set: { lock: new Date() } },
        { sort: { createdAt: 1 } },
      )
      const item = findResult.ok && findResult.value
      if (item) {
        itemId = item._id

        // Process
        const res = process(item.data)

        // Remove from cache
        this.queue.remove({ _id: item._id })

        return res
      }
      return false
    } catch (err) {
      console.error(`Error when processing ${this.name} queue`, err)
      // TODO retry failures
      try {
        this.queue.update({ _id: itemId }, { $unset: { lock: '' } })
      } catch (updateErr) {
        console.error(`Fatal error processing ${this.name} queue, unable to update queue collection`, updateErr)
      }
      return false
    }
  }
}
