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
          { find: (duty) ->
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
            find: (team) ->
              sel = {parentId: team._id}
              unless share.isManagerOrLead(userId,[ departmentId ])
                sel = _.extend(sel,dutiesPublicPolicy)
              return duties.find(sel)
            children: [
              { find: (duty,team) ->
                if share.isManagerOrLead(userId,[ departmentId ])
                  return signups.find({parentId: team._id})
                else return null
                children: [
                  { find: (signup,duty,team) ->
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
                  { find: (duty,team,dept) ->
                    if share.isManagerOrLead(userId,[ divisionId ])
                      return signups.find({parentId: {$in: [team._id, dept._id]}})
                    else return null
                    children: [
                      { find: (signup,duty,team) ->
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
                      { find: (duty,team,dept,division) ->
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
            sel = {userId: userId}
            return signups.find(sel)
          else return null
        children: [
          { find: (signup) -> return duties.find(signup.shiftId) }
          { find: (signup) -> return share.Team.find(signup.parentId) }
          { find: (signup) ->
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
          { find: (duty) ->
              if duty
                if userId && (userId == actualUserId) || share.isManagerOrLead(userId, [duty.parentId])
                  return signups.find({shiftId: duty._id, userId: userId})
                else return null
              else return null
            children: [
              { find: (signup,duty) ->
                if duty
                  if type == "TeamShifts" || type == "TeamTasks"
                    return share.Team.find(duty.parentId)
                  else if type == "Lead"
                    t = share.Team.find(duty.parentId)
                    if t.count() > 0 then return t else
                    dt = share.Department.find(duty.parentId)
                    if dt.count() > 0 then return dt else
                    dv = share.Division.find(duty.parentId)
                    return dv
                else return null
              },
              { find: (signup,duty) ->
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

  createPublicationAllDuties = (type,duties) ->
    Meteor.publish "#{eventName}.Volunteers.#{type}", (sel={},limit=10) ->
      sel = _.extend(sel,dutiesPublicPolicy)
      if this.userId
        sel = filterForPublic(this.userId, sel)
      # console.log(JSON.stringify(sel, null, 4))
      return duties.find(sel,{limit: limit})

  createPublicationAllDuties("TeamShifts",share.TeamShifts)
  createPublicationAllDuties("TeamTasks",share.TeamTasks)
  createPublicationAllDuties("Projects",share.Projects)
  createPublicationAllDuties("Lead",share.Lead)

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", (userId) ->
    # XXX access to all leads, or only those leads that need to know ?
    if share.isManagerOrLead(this.userId)
      share.VolunteerForm.find({userId: userId})
    else
      if !userId? or this?.userId == userId
        share.VolunteerForm.find({userId: this.userId},{fields: {private_notes: 0}})
      else
        return null

  # Reactive publication sorted by user preferences
  Meteor.publish "#{eventName}.Volunteers.team.ByUserPref", (quirks,skills) ->
    if this.userId
      ReactiveAggregate(this, share.Team, [
        { $project: {
          quirks:  { $ifNull: [ "$quirks", [] ] },
          skills:  { $ifNull: [ "$skills", [] ] },
          intq: {"$setIntersection": [ quirks, "$quirks" ] },
          ints: {"$setIntersection": [ skills, "$skills" ] },
        }},
        {$project: {
          subq: { $size: { $ifNull: [ "$intq", [] ] } },
          subs: { $size: { $ifNull: [ "$ints", [] ] } },
        }},
        {$project: {
          score: { $sum: [ "$subq", "$subs" ]}
        }},
        { $sort: { score: -1 } }
      ])

  ######################################
  # Below here, all public information #
  ######################################

  # not reactive
  Meteor.publish "#{eventName}.Volunteers.organization", () ->
    sel = {}
    unless (not this.userId) || share.isManagerOrLead(this.userId)
      sel = unitPublicPolicy
    dp = share.Department.find(sel)
    t = share.Team.find(sel)
    dv = share.Division.find(sel)
    return [dv,dp,t]

  Meteor.publish "#{eventName}.Volunteers.team", (sel={}) ->
    if this.userId && share.isManagerOrLead(this.userId)
      share.Team.find(sel)
    else
      share.Team.find(_.extend(sel,unitPublicPolicy))

  Meteor.publish "#{eventName}.Volunteers.division", (sel={}) ->
    if this.userId && share.isManagerOrLead(this.userId)
      share.Division.find(sel)
    else
      share.Division.find(_.extend(sel,unitPublicPolicy))

  Meteor.publish "#{eventName}.Volunteers.department", (sel={}) ->
    if this.userId && share.isManagerOrLead(this.userId)
      share.Department.find(sel)
    else
      share.Department.find(_.extend(sel,unitPublicPolicy))
