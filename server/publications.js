/* globals __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { ReactiveAggregate } from 'meteor/jcbernack:reactive-aggregate'
import { Roles } from 'meteor/piemonkey:roles'
import { check, Match } from 'meteor/check'

import { collections } from '../both/collections/initCollections'

const share = __coffeescriptShare

export const initPublications = (eventName) => {
  const prefix = `${eventName}.Volunteers`
  const dutiesPublicPolicy = { policy: { $in: ['public', 'requireApproval'] } }

  const filterForPublic = (userId, sel) => {
    if (share.isManager()) {
      return sel
    }
    // getRolesForUser includes all roles, e.g. if user is lead of a department,
    // returns the department and all teams within it
    const allOrgUnitIds = Roles.getRolesForUser(Meteor.userId(), eventName)
    let query = { ...sel, ...dutiesPublicPolicy }
    if (allOrgUnitIds.length > 0) {
      query = { $or: [{ parentId: { $in: allOrgUnitIds } }, sel] }
    }
    return query
  }

  const findDutiesWithSignupsAndUsers = (type, isManagerOrLead, passedTeamId) => ({
    find(team) {
      // When chained after other publishComposite steps gets passed the results of the previous
      // query, so needs an id passed to the function or a org unit query step just before
      const teamId = passedTeamId || (team && team._id)
      let sel = { parentId: teamId }
      if (!isManagerOrLead) {
        sel = _.extend(sel, dutiesPublicPolicy)
      }
      return collections.dutiesCollections[type].find(sel)
    },
    children: [
      {
        find(duty) {
          if (isManagerOrLead) {
            return collections.signups.find({ shiftId: duty._id })
          }
          return null
        },
        children: [
          {
            find(signup) {
              if (signup && isManagerOrLead) {
                return Meteor.users.find(signup.userId)
              }
              return null
            },
          },
        ],
      },
    ],
  })

  // return all signups related to this team.
  // Restricted to team lead
  Meteor.publishComposite(`${prefix}.Signups.byTeam`,
    function publishSignupsByTeam(teamId, type) {
      const isManagerOrLead = share.isManagerOrLead(this.userId, [teamId])
      return findDutiesWithSignupsAndUsers(type, isManagerOrLead, teamId)
    })

  // all given a department id, return all teams and all signups related
  // to this department. Restricted to department lead
  Meteor.publishComposite(`${prefix}.Signups.byDept`,
    function publishSignupsByDept(departmentId, type) {
      const isManagerOrLead = share.isManagerOrLead(this.userId, [departmentId])
      return {
        find() { return share.Team.find({ parentId: departmentId }) },
        children: [
          findDutiesWithSignupsAndUsers(type, isManagerOrLead, departmentId),
          findDutiesWithSignupsAndUsers(type, isManagerOrLead),
        ],
      }
    })

  // all given a division id, return all teams and all signups related
  // to this division. Restricted to division lead
  Meteor.publishComposite(`${prefix}.Signups.byDivision`,
    function publishSignupsByDiv(divisionId, type) {
      const isManagerOrLead = share.isManagerOrLead(this.userId, [divisionId])
      return {
        find() { return share.Department.find({ parentId: divisionId }) },
        children: [
          {
            find(dept) { return share.Team.find({ parentId: dept._id }) },
            children: [
              findDutiesWithSignupsAndUsers(type, isManagerOrLead),
            ],
          },
          findDutiesWithSignupsAndUsers(type, isManagerOrLead),
          findDutiesWithSignupsAndUsers(type, isManagerOrLead, divisionId),
        ],
      }
    })

  // given a user id return all signups, shift and teams related to this user.
  // restricted to user or manager
  Meteor.publishComposite(`${prefix}.Signups.byUser`,
    function publishSignupsByUser(pubUserId, types = []) {
      const userId = pubUserId || this.userId
      const query = { userId }
      if (types.length > 0) query.type = { $in: types }
      return {
        find() {
          if ((userId === this.userId) || share.isManager()) {
            return collections.signups.find(query)
          }
          return null
        },
        children: [
          { find: ({ type, shiftId }) => collections.dutiesCollections[type].find(shiftId) },
          {
            find({ parentId }) {
              let unit = share.Team.find(parentId)
              if (unit.count() > 0) {
                return unit
              }
              unit = share.Department.find(parentId)
              return unit
            },
          },
          {
            find({ userId: signupUserId, parentId }) {
              if (parentId && share.isManagerOrLead(userId, [parentId])) {
                return Meteor.users.find(signupUserId)
              }
              return null
            },
          },
        ],
      }
    })

  // given a duty id return the team and all signups related to the current user
  // Restricted to user or duty.parentId lead
  Meteor.publishComposite(`${prefix}.Signups.byDuty`,
    function publishSignupByDuty(id, type, userId = this.userId) {
      const currentUserId = this.userId
      return {
        find() { return collections.dutiesCollections[type].find(id) },
        children: [
          {
            find(duty) {
              if (duty && (userId === currentUserId
                || share.isManagerOrLead(currentUserId, [duty.parentId]))) {
                return collections.signups.find({ shiftId: duty._id, userId })
              }
              return null
            },
            children: [
              {
                find(signup, duty) {
                  if (signup && share.isManagerOrLead(currentUserId, [duty.parentId])) {
                    return Meteor.users.find(signup.userId)
                  }
                  return null
                },
              },
            ],
          },
        ],
      }
    })

  Meteor.publish(`${prefix}.duties`, function publishAllDuties(type, sel = {}) {
    check(type, Match.OneOf(...Object.keys(collections.dutiesCollections)))
    let query = { ...sel, ...dutiesPublicPolicy }
    if (this.userId) {
      query = filterForPublic(this.userId, query)
    }
    return ReactiveAggregate(this, collections.dutiesCollections[type], [
      { $match: query },
      {
        $lookup: {
          from: collections.signups._name,
          localField: '_id',
          foreignField: 'shiftId',
          as: 'signups',
        },
      },
      { $unwind: { path: '$signups', preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: '$_id',
          signedUp: {
            $sum: {
              $cond: [{ $in: ['$signups.status', ['confirmed', 'pending']] }, 1, 0],
            },
          },
          min: { $first: '$min' },
          max: { $first: '$max' },
          parentId: { $first: '$parentId' },
          title: { $first: '$title' },
          description: { $first: '$description' },
          priority: { $first: '$priority' },
          policy: { $first: '$policy' },
          start: { $first: '$start' },
          end: { $first: '$end' },
          staffing: { $first: '$staffing' },
        },
      },
    ])
  })

  Meteor.publish(`${eventName}.Volunteers.shiftGroups`, function publishSiftGroups(sel = {}) {
    let query = { ...sel, ...dutiesPublicPolicy }
    if (this.userId) {
      query = filterForPublic(this.userId, query)
    }
    return ReactiveAggregate(this, share.TeamShifts, [
      { $match: query },
      {
        $group: {
          _id: '$rotaId',
          parentId: { $first: '$parentId' },
          title: { $first: '$title' },
          description: { $first: '$description' },
          priority: { $first: '$priority' },
          policy: { $first: '$policy' },
          length: {
            $first: {
              $divide: [
                { $subtract: ['$end', '$start'] },
                3600000,
              ],
            },
          },
        },
      },
    ], { clientCollection: `${eventName}.Volunteers.shiftGroups` })
  })
}
