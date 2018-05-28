share.initPublications = (eventName) ->

  dutiesPublicPolicy = { policy: { $in: ["public", "requireApproval"] } }
  unitPublicPolicy = { policy: { $in: ["public"] } }

  filterForPublic = (userId, sel) ->
    unless share.isManager() #Roles.userIsInRole(userId, 'manager', eventName)
      #getRolesForUser includes all roles, e.g. if user is lead of a department,
      #returns the department and all teams within it
      allOrgUnitIds = Roles.getRolesForUser(Meteor.userId(), eventName)
      sel = _.extend(sel,dutiesPublicPolicy)
      if allOrgUnitIds.length > 0
        sel = { $or: [ parentId: { $in: allOrgUnitIds }, sel ] }
    sel

  # all given a team id, return all signups related to this team.
  # Restricted to team lead
  createPublicationTeam = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byTeam",(teamId) ->
      userId = this.userId
      return {
        find: () ->
          sel = {parentId: teamId}
          unless share.isManagerOrLead(userId,[ teamId ])
            sel = _.extend(sel,dutiesPublicPolicy)
          return duties.find(sel)
        children: [
          {
            find: (duty) ->
              if share.isManagerOrLead(userId,[ teamId ])
                return signups.find({shiftId: duty._id})
              else return null
            children: [
              { find: (signup,duty) ->
                if signup
                  if share.isManagerOrLead(userId,[ teamId ])
                    return Meteor.users.find(signup.userId)
                  else return null
                else return null
              }
            ]
          }
        ]
      }
    )

  createPublicationTeam("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPublicationTeam("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPublicationTeam("ProjectSignups",share.ProjectSignups,share.Projects)
  createPublicationTeam("LeadSignups",share.LeadSignups,share.Lead)

  # all given a department id, return all teams and all signups related
  # to this department. Restricted to department lead
  createPublicationDept = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byDepartment", (departmentId) ->
      userId = this.userId
      return {
        find: () -> return share.Team.find({parentId: departmentId})
        children: [
          {
            find: () ->
              sel = {parentId: departmentId}
              unless share.isManagerOrLead(userId,[ departmentId ])
                sel = _.extend(sel,dutiesPublicPolicy)
              return duties.find(sel)
            children: [
              {
                find: (duty) ->
                  if share.isManagerOrLead(userId,[ departmentId ])
                    return signups.find({shiftId: duty._id})
                  else return null
                children: [
                  { find: (signup,duty) ->
                    if signup
                      if share.isManagerOrLead(userId,[ departmentId ])
                        return Meteor.users.find(signup.userId)
                      else return null
                    else return null
                  }
                ]
              }
            ]
          }, {
            find: (team) ->
              sel = {parentId: team._id}
              unless share.isManagerOrLead(userId,[ departmentId ])
                sel = _.extend(sel,dutiesPublicPolicy)
              return duties.find(sel)
            children: [
              {
                find: (duty,team) ->
                  if share.isManagerOrLead(userId,[ departmentId ])
                    return signups.find({parentId: team._id})
                  else return null
                children: [
                  {
                    find: (signup,duty,team) ->
                      if signup
                        if share.isManagerOrLead(userId,[ departmentId ])
                          return Meteor.users.find(signup.userId)
                        else return null
                      else return null
                  }
                ]
              }
            ]
          }
        ]
      }
    )

  createPublicationDept("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPublicationDept("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPublicationDept("ProjectSignups",share.ProjectSignups,share.Projects)
  createPublicationDept("LeadSignups",share.LeadSignups,share.Lead)

  # all given a division id, return all teams and all signups related
  # to this division. Restricted to division lead
  createPublicationDivision = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byDivision", (divisionId) ->
      userId = this.userId
      return {
        find: () -> return share.Department.find({parentId: divisionId})
        children: [
          {
            find: (dept) -> return share.Team.find({parentId: dept._id})
            children: [
              {
                find: (team,dept) ->
                  sel = {parentId: team._id}
                  unless share.isManagerOrLead(userId,[ divisionId ])
                    sel = _.extend(sel,dutiesPublicPolicy)
                  return duties.find(sel)
                children: [
                  {
                    find: (duty,team,dept) ->
                      if share.isManagerOrLead(userId,[ divisionId ])
                        return signups.find({parentId: {$in: [team._id, dept._id]}})
                      else return null
                    children: [
                      {
                        find: (signup,duty,team) ->
                          if signup
                            if share.isManagerOrLead(userId,[ divisionId ])
                              return Meteor.users.find(signup.userId)
                            else return null
                          else return null
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    )

  createPublicationDivision("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPublicationDivision("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPublicationDivision("ProjectSignups",share.ProjectSignups,share.Projects)
  createPublicationDivision("LeadSignups",share.LeadSignups,share.Lead)

  # return all divisions, departments and teams signups. restricted to manager
  createPublicationManager = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.Manager", () ->
      userId = this.userId
      return {
        find: () -> return share.Division.find()
        children: [
          {
            find: (division) -> return share.Department.find({parentId: division._id})
            children: [
              {
                find: (dept,division) -> return share.Team.find({parentId: dept._id})
                children: [
                  {
                    find: (team,dept,division) ->
                      sel = {parentId: {$in: [team._id, dept._id, division._id]}}
                      unless share.isManagerOrLead(userId,[ division._id ])
                        sel = _.extend(sel,dutiesPublicPolicy)
                      return duties.find(sel)
                    children: [
                      {
                        find: (duty,team,dept,division) ->
                          if share.isManagerOrLead(userId,[ division._id ])
                            return signups.find({parentId: {$in: [team._id, dept._id, division._id]}})
                          else return null
                        children: [
                          { find: (signup,duty,team,dept,division) ->
                            if signup
                              if share.isManagerOrLead(userId,[ division._id ])
                                return Meteor.users.find(signup.userId)
                              else return null
                            else return null
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    )

  createPublicationManager("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPublicationManager("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPublicationManager("ProjectSignups",share.ProjectSignups,share.Projects)
  createPublicationManager("LeadSignups",share.LeadSignups,share.Lead)

  # given a user id return all signups, shift and teams related to this user.
  # restricted to user or manager
  createPublicationUser = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byUser", (userId) ->
      actualUserId = this.userId
      return {
        find: () ->
          if userId == actualUserId || share.isManager()
            return signups.find({userId})
          else return null
        children: [
          { find: (signup) -> return duties.find(signup.shiftId) }
          { find: (signup) ->
            unit = share.Team.find(signup.parentId)
            if unit.count() > 0
              return unit
            else
              unit = share.Department.find(signup.parentId)
              return unit
          }
          {
            find: (signup) ->
              if signup
                if share.isManagerOrLead(userId,[ signup.parentId ])
                  return Meteor.users.find(signup.userId)
                else return null
              else return null
          }
        ]
      }
    )

  createPublicationUser("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPublicationUser("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPublicationUser("ProjectSignups",share.ProjectSignups,share.Projects)
  createPublicationUser("LeadSignups",share.LeadSignups,share.Lead)

  # given a duty id return the team and all signups related to the current user
  # Restricted to user or duty.parentId lead
  createPublicationDuty = (type,duties,signups) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byDuty", (id,userId = this.userId) ->
      actualUserId = this.userId
      return {
        find: () -> return duties.find(id)
        children: [
          {
            find: (duty) ->
              if duty
                if userId && (userId == actualUserId) || share.isManagerOrLead(userId, [duty.parentId])
                  return signups.find({shiftId: duty._id, userId: userId})
                else return null
              else return null
            children: [
              {
                find: (signup,duty) ->
                  if signup
                    if share.isManagerOrLead(userId,[ duty.parentId ])
                      return Meteor.users.find(signup.userId)
                    else return null
                  else return null
              }
            ]
          }
        ]
      }
    )

  createPublicationDuty("TeamShifts",share.TeamShifts,share.ShiftSignups)
  createPublicationDuty("TeamTasks",share.TeamTasks,share.TaskSignups)
  createPublicationDuty("Projects",share.Projects,share.ProjectSignups)
  createPublicationDuty("Lead",share.Lead,share.LeadSignups)

  createPublicationSimpleDuty = (type,duties,signups) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.simple", () ->
      return {
        find: () -> return duties.find()
        children: [
          { find: (duty) ->
            unit = share.Team.find(duty.parentId)
            if unit.count() > 0
              return unit
            else
              unit = share.Department.find(duty.parentId)
              return unit
          }
        ]
      }
    )

  createPublicationSimpleDuty("TeamShifts")
  createPublicationSimpleDuty("TeamTasks")
  createPublicationSimpleDuty("Projects")
  createPublicationSimpleDuty("Lead")

  createPublicationAllDuties = (type,duties,signups) ->
    Meteor.publish "#{eventName}.Volunteers.#{type}", (sel={},limit=10) ->
      sel = _.extend(sel,dutiesPublicPolicy)
      if this.userId
        sel = filterForPublic(this.userId, sel)
      ReactiveAggregate(this, duties, [
        { $match: sel },
        { $lookup: {
          from: signups._name,
          localField: "_id",
          foreignField: "shiftId",
          as: "signups"
        }},
        { $unwind: {path: "$signups", "preserveNullAndEmptyArrays": true} },
        { $group: {
          _id: "$_id",
          signedUp: { $sum: { "$cond": [
            { $eq: [ "$signups.status", "confirmed" ] },1,0 ]
          }},
          min: { $first: "$min" },
          max: { $first: "$max" },
          parentId:{ $first: "$parentId" },
          title: { $first: "$title" },
          description: { $first: "$description" },
          priority: { $first: "$priority" },
          policy: { $first: "$policy" },
          start: { $first: "$start" },
          end: { $first: "$end" },
          staffing: { $first: "$staffing" },
        }},
      ])

  createPublicationAllDuties("TeamShifts",share.TeamShifts,share.ShiftSignups)
  createPublicationAllDuties("TeamTasks",share.TeamTasks,share.TaskSignups)
  createPublicationAllDuties("Projects",share.Projects, share.ProjectSignups)
  createPublicationAllDuties("Lead",share.Lead, share.LeadSignups)

  Meteor.publish "#{eventName}.Volunteers.shiftGroups", (sel={},limit=10) ->
    sel = _.extend(sel,dutiesPublicPolicy)
    if this.userId
      sel = filterForPublic(this.userId, sel)
    ReactiveAggregate(this, share.TeamShifts, [
      { $match: sel },
      { $group: {
          _id: "$groupId",
          parentId: { $first: "$parentId" },
          title: { $first: "$title" },
          description: { $first: "$description" },
          priority: { $first: "$priority" },
          policy: { $first: "$policy" },
          length: { $first: {
            $divide: [
              { $subtract: [ "$end", "$start" ]},
              3600000,
            ]},
          },
        },
      },
    ], { clientCollection: "#{eventName}.Volunteers.shiftGroups" })

  Meteor.publish "#{eventName}.Volunteers.volunteerForm.list", (userIds) ->
    if share.isManager() # publish manager only information
      share.VolunteerForm.find({userId: {$in: userIds}})
    else if share.isLead()
      # TODO: the fields of the should have a field 'confidential that allow
      # here to filter which information to publish to all leads
      share.VolunteerForm.find({userId: {$in: userIds}})
    else
      return null

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", (userId) ->
    if share.isManager()
      share.VolunteerForm.find({userId: userId})
    else if share.isLead()
      share.VolunteerForm.find({userId: userId})
    else
      if !userId? or this?.userId == userId
        share.VolunteerForm.find({userId: this.userId},{fields: {private_notes: 0}})
      else
        return null

  # this pipeline sort add the totalscore field to a team
  teamPipeline = [
    # get all the shifts associated to this team
    { $lookup: {
      from: share.TeamShifts._name,
      localField: "_id",
      foreignField: "parentId",
      as: "duties"
    }},
    { $unwind: "$duties" },
    # project the results in mongo 3.4 use addfields instead
    { $project: {
      name: 1,
      description: 1,
      parentId: 1,
      quirks: 1,
      skills: 1,
      duties: 1,
      p : {
        $cond: [{ $eq: [ "$duties.priority", "normal"]},1,
          { $cond: [{ $eq: [ "$duties.priority", "important"]},3,
            {
              $cond: [{ $eq: [ "$duties.priority", "essential"]},5,0]
            }
          ]}
        ]
      }}
    },
    { $group: {
      _id: "$_id",
      # types: { $addToSet: "$duties.priority" },
      totalscore: { $sum: "$p"}, # assign a score to each team based on its shifts' priority
      name: {$first: "$name"},
      description : {$first: "$description"},
      parentId: {$first: "$parentId"}
      quirks: {$first: "$quirks"},
      skills: {$first: "$skills"},
    }},
  ]

  # Reactive publication sorted by user preferences
  # I use the pipeline above + adding one more field for the userPref
  Meteor.publish "#{eventName}.Volunteers.team.ByUserPref", (quirks,skills) ->
    if this.userId
      ReactiveAggregate(this, share.Team, teamPipeline.concat([
        { $project: {
          name: 1,
          description: 1,
          parentId: 1,
          totalscore: 1
          quirks:  { $ifNull: [ "$quirks", [] ] },
          skills:  { $ifNull: [ "$skills", [] ] },
          intq: {"$setIntersection": [ quirks, "$quirks" ] },
          ints: {"$setIntersection": [ skills, "$skills" ] },
        }},
        {$project: {
          name: 1,
          description: 1,
          parentId: 1,
          quirks: 1,
          skills: 1,
          totalscore: 1
          subq: { $size: { $ifNull: [ "$intq", [] ] } },
          subs: { $size: { $ifNull: [ "$ints", [] ] } },
        }},
        {$project: {
          name: 1,
          description: 1,
          parentId: 1,
          quirks: 1,
          skills: 1,
          totalscore: 1
          # assign a score to the team w.r.t. the user preferences
          userpref: { $sum: [ "$subq", "$subs" ]}
        }},
        # remove all teams without duties
        { $match: { totalscore: { $gt: 0 } }},
        { $sort: { totalscore: -1 } }
      ]))

  Meteor.publish "#{eventName}.Volunteers.team", (sel={}) ->
    unless share.isManager()
      sel = _.extend(sel,unitPublicPolicy)
    ReactiveAggregate(this, share.Team,
      [ { $match: sel } ].concat(
        teamPipeline.concat( [
          { $match: { totalscore: { $gt: 0 } }},
          { $sort: { totalscore: -1 } }
          ]
        )
      )
    )
  ######################################
  # Below here, all public information #
  ######################################

  # not reactive
  Meteor.publish "#{eventName}.Volunteers.organization", () ->
    sel = {}
    unless (not this.userId) || share.isManager()
      sel = unitPublicPolicy
    dp = share.Department.find(sel)
    t = share.Team.find(sel)
    dv = share.Division.find(sel)
    return [dv,dp,t]

  Meteor.publish "#{eventName}.Volunteers.unitAggregation.byDepartment", (deptId) ->
    if this.userId && share.isManagerOrLead(this.userId,[deptId])
      parentId = deptId
      dept = share.Department.findOne(parentId)
      teams = share.Team.find({ parentId }).fetch()
      share.DepartmentStats(parentId)
      teams.forEach((team) -> share.TeamStats(team._id))
      teams.push(dept)
      share.UnitAggregation.find({_id: {$in: _.pluck(teams,'_id')}})
    else null

  Meteor.publish "#{eventName}.Volunteers.unitAggregation.byTeam", (teamId) ->
    if this.userId && share.isManagerOrLead(this.userId,[teamId])
      share.TeamStats(teamId)
      share.UnitAggregation.find({_id: teamId})
    else null

  # XXX leads of a non public division should be able to see it
  Meteor.publish "#{eventName}.Volunteers.division", (sel={}) ->
    if this.userId && share.isManager()
      share.Division.find(sel)
    else
      share.Division.find(_.extend(sel,unitPublicPolicy))

  # XXX leads of a non public department should be able to see it
  Meteor.publish "#{eventName}.Volunteers.department", (sel={}) ->
    if this.userId && share.isManager()
      share.Department.find(sel)
    else
      share.Department.find(_.extend(sel,unitPublicPolicy))

  # these two publications are used in the teamEdit and departmentEdit forms
  Meteor.publish "#{eventName}.Volunteers.team.backend", (parentId) ->
    if this.userId && share.isManagerOrLead(this.userId,[parentId])
      share.Team.find({parentId})
    else
      share.Team.find(_.extend({parentId},unitPublicPolicy))

  Meteor.publish "#{eventName}.Volunteers.department.backend", (parentId) ->
    if this.userId && share.isManagerOrLead(this.userId,[parentId])
      share.Department.find({parentId})
    else
      share.Department.find(_.extend({parentId},unitPublicPolicy))
