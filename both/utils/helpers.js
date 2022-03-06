import { Meteor } from 'meteor/meteor'

export const wrapAsync = (func) => Meteor.wrapAsync((...args) => {
  const cb = args[args.length - 1]
  const inputs = args.slice(0, -1)
  func(...inputs)
    .then(ticket => cb(null, ticket))
    .catch(err => cb(err))
})
