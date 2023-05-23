import { Meteor } from 'meteor/meteor'
import { ReactiveAggregate } from 'meteor/jcbernack:reactive-aggregate'
import { Roles } from 'meteor/alanning:roles'
import { check, Match } from 'meteor/check'

export const initPublications = (volunteersClass) => {
  const { collections, eventName, services: { auth } } = volunteersClass
  const prefix = `${eventName}.Volunteers`

  const dutiesPublicPolicy = { policy: { $in: ['public', 'requireApproval'] } }
  const unitPublicPolicy = { policy: { $in: ['public'] } }

  Meteor.publish(`${prefix}.volunteerForm.list`, (userIds = []) => {
    if (auth.isManager()) { // publish manager only information
      return collections.volunteerForm.find({ userId: { $in: userIds } })
    }
    if (auth.isALead()) {
      // TODO: the fields of the should have a field 'confidential that allow
      // here to filter which information to publish to all leads
      return collections.volunteerForm.find({ userId: { $in: userIds } })
    }
    return null
  })

  Meteor.publish(`${prefix}.volunteerForm`, function publishVolunteerForm(userId = this.userId) {
    if (auth.isALead()) {
      return collections.volunteerForm.find({ userId })
    }
    if (!userId || (this?.userId === userId)) {
      return collections.volunteerForm
        .find({ userId: this.userId }, { fields: { private_notes: 0 } })
    }
    return null
  })

  // this pipeline sort add the totalscore field to a team
  const teamPipeline = [
    // get all the shifts associated to this team
    {
      $lookup: {
        from: collections.shift._name,
        localField: '_id',
        foreignField: 'parentId',
        as: 'duties',
      },
    },
    { $unwind: '$duties' },
    {
      $addFields: {
        p: {
          $cond: [{ $eq: ['$duties.priority', 'normal'] }, 1,
            {
              $cond: [{ $eq: ['$duties.priority', 'important'] }, 3,
                {
                  $cond: [{ $eq: ['$duties.priority', 'essential'] }, 5, 0],
                },
              ],
            },
          ],
        },
      },
    },
    {
      $group: {
        _id: '$_id',
        // types: { $addToSet: "$duties.priority" },
        totalscore: { $sum: '$p' }, // assign a score to each team based on its shifts' priority
        name: { $first: '$name' },
        description: { $first: '$description' },
        parentId: { $first: '$parentId' },
        quirks: { $first: '$quirks' },
        skills: { $first: '$skills' },
      },
    },
  ]

  // Reactive publication sorted by user preferences
  // I use the pipeline above + adding one more field for the userPref
  Meteor.publish(`${prefix}.team.ByUserPref`, function publishTeamsByUserPrefs(quirks = [], skills = []) {
    if (!this.userId) {
      throw new Meteor.Error('401', 'You need to be logged in for this')
    }
    return ReactiveAggregate(this, collections.team, teamPipeline.concat([
      {
        $addFields: {
          intq: { $setIntersection: [quirks, '$quirks'] },
          ints: { $setIntersection: [skills, '$skills'] },
        },
      },
      {
        $addFields: {
          subq: { $size: { $ifNull: ['$intq', []] } },
          subs: { $size: { $ifNull: ['$ints', []] } },
        },
      },
      {
        $addFields: {
          // assign a score to the team w.r.t. the user preferences
          userpref: { $sum: ['$subq', '$subs'] },
        },
      },
      // remove all teams without duties
      { $match: { totalscore: { $gt: 0 } } },
      { $sort: { totalscore: -1 } },
    ]))
  })

  Meteor.publish(`${prefix}.team`, function publishTeam(sel = {}) {
    let selector = sel
    if (!auth.isManager()) {
      selector = { ...sel, ...unitPublicPolicy }
    }
    return ReactiveAggregate(this, collections.team,
      [{ $match: selector }].concat(
        teamPipeline.concat([
          { $match: { totalscore: { $gt: 0 } } },
          { $sort: { totalscore: -1 } },
        ]),
      ))
  })
  // #####################################
  // Below here, all public information #
  // #####################################

  Meteor.publish(`${prefix}.organization`, function publishOrg() {
    let sel = {}
    if (this.userId && !auth.isManager()) {
      sel = unitPublicPolicy
    }
    const dp = collections.department.find(sel)
    const t = collections.team.find(sel)
    const dv = collections.division.find(sel)
    return [dv, dp, t]
  })

  Meteor.publish(`${prefix}.division`, function publishDiv(sel = {}) {
    if (this.userId && auth.isALead()) {
      return collections.division.find(sel)
    }
    return collections.division.find(_.extend(sel, unitPublicPolicy))
  })

  Meteor.publish(`${prefix}.department`, function publishDept(sel = {}) {
    if (this.userId && auth.isALead()) {
      return collections.department.find(sel)
    }
    return collections.department.find(_.extend(sel, unitPublicPolicy))
  })

  const filterForPublic = (userId, sel) => {
    if (auth.isManager()) {
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

  const findDutiesWithSignupsAndUsers = (type, isLead, passedTeamId) => ({
    find(team) {
      // When chained after other publishComposite steps gets passed the results of the previous
      // query, so needs an id passed to the function or a org unit query step just before
      const teamId = passedTeamId || (team && team._id)
      let sel = { parentId: teamId }
      if (!isLead) {
        sel = _.extend(sel, dutiesPublicPolicy)
      }
      return collections.dutiesCollections[type].find(sel)
    },
    children: [
      {
        find(duty) {
          return collections.signups.find({ shiftId: duty._id })
        },
        children: [
          {
            find(signup) {
              if (signup && isLead) {
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
      const isLead = auth.isLead(this.userId, teamId)
      return findDutiesWithSignupsAndUsers(type, isLead, teamId)
    })

  // all given a department id, return all teams and all signups related
  // to this department. Restricted to department lead
  Meteor.publishComposite(`${prefix}.Signups.byDept`,
    function publishSignupsByDept(departmentId, type) {
      const isLead = auth.isLead(this.userId, departmentId)
      return {
        find() { return collections.team.find({ parentId: departmentId }) },
        children: [
          findDutiesWithSignupsAndUsers(type, isLead, departmentId),
          findDutiesWithSignupsAndUsers(type, isLead),
        ],
      }
    })

  // all given a division id, return all teams and all signups related
  // to this division. Restricted to division lead
  Meteor.publishComposite(`${prefix}.Signups.byDivision`,
    function publishSignupsByDiv(divisionId, type) {
      const isLead = auth.isLead(this.userId, divisionId)
      return {
        find() { return collections.department.find({ parentId: divisionId }) },
        children: [
          {
            find(dept) { return collections.team.find({ parentId: dept._id }) },
            children: [
              findDutiesWithSignupsAndUsers(type, isLead),
            ],
          },
          findDutiesWithSignupsAndUsers(type, isLead),
          findDutiesWithSignupsAndUsers(type, isLead, divisionId),
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
          if ((userId === this.userId) || auth.isManager() || auth.isALead()) {
            return collections.signups.find(query)
          }
          return null
        },
        children: [
          { find: ({ type, shiftId }) => collections.dutiesCollections[type].find(shiftId) },
          {
            find({ parentId }) {
              let unit = collections.team.find(parentId)
              if (unit.count() > 0) {
                return unit
              }
              unit = collections.department.find(parentId)
              return unit
            },
          },
          {
            find({ userId: signupUserId, parentId }) {
              if (parentId && auth.isLead(userId, parentId)) {
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
                || auth.isLead(currentUserId, duty.parentId))) {
                return collections.signups.find({ shiftId: duty._id, userId })
              }
              return null
            },
            children: [
              {
                find(signup, duty) {
                  if (signup && auth.isLead(currentUserId, duty.parentId)) {
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
    return ReactiveAggregate(this, collections.shift, [
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
