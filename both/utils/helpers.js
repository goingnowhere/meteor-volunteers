import { Meteor } from 'meteor/meteor'

export const wrapAsync = (func) => Meteor.wrapAsync((...args) => {
  const cb = args[args.length - 1]
  const inputs = args.slice(0, -1)
  func(...inputs)
    .then(ticket => cb(null, ticket))
    .catch(err => cb(err))
})

export const displayName = ({ profile }) =>
  profile?.nickname
    || profile?.firstName
    || (profile?.lastName && `Mx ${profile.lastName}`)
    || 'anonymous nobody'

export const rawCollectionOp = wrapAsync((collection, operation, ...args) =>
  collection.rawCollection()[operation](...args))
