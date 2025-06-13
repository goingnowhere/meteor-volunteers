import { Meteor } from 'meteor/meteor'

export const initAuthMixins = (authService) => ({
  /** check if the first argument is a String and compares it with the current user Id
     Or if the first argument is an object with a field userId
     Or if the first argument is an object with a field _id  */
  isSameUser: ({ run, ...methodOptions }) => ({
    ...methodOptions,
    run(args) {
    // the doc must belong to the user
      if (!this.userId || (![args, args.userId, args._id].includes(this.userId))) {
        throw new Meteor.Error('403', "You don't have permission for this operation")
      }
      return run(args)
    },
  }),

  isSameUserOrManager: ({ run, ...methodOptions }) => ({
    ...methodOptions,
    run(args) {
    // if the current user is not a manager, then
    // the doc must belong to the user
      if (!this.userId
      || (![args, args.userId, args._id].includes(this.userId) && !authService.isManager())) {
        throw new Meteor.Error('403', "You don't have permission for this operation")
      }
      return run(args)
    },
  }),

  isManager: ({ run, ...methodOptions }) => ({
    ...methodOptions,
    run(args) {
      if (!authService.isManager()) {
        throw new Meteor.Error('403', "You don't have permission for this operation")
      }
      return run(args)
    },
  }),

  /** If arg is a parentId or an object containing one, are we a lead of that unit or manager?
  * If we don't provide a parentId, throw unless we're a manager */
  isLead: ({ run, ...methodOptions }) => ({
    ...methodOptions,
    run(args) {
    // Check if lead of parentId from args if it has it
      const teamId = typeof args === 'object' ? args.parentId ?? args.teamId ?? args.deptId : args
      if (!authService.isManager(this.userId) && !authService.isLead(this.userId, teamId)) {
        throw new Meteor.Error('403', "You don't have permission for this operation")
      }
      return run(args)
    },
  }),

  // Specific mixin to allow any lead not just ones for a specific team
  isAnyLead: ({ run, ...methodOptions }) => ({
    ...methodOptions,
    run(args) {
      if (!authService.isALead(this.userId)) {
        throw new Meteor.Error('403', "You don't have permission for this operation")
      }
      return run(args)
    },
  }),

  isLoggedIn: ({ run, ...methodOptions }) => ({
    ...methodOptions,
    run(args) {
      if (!this.userId) {
        throw new Meteor.Error('401', 'You need to be logged in for this operation')
      }
      return run(args)
    },
  }),
})
