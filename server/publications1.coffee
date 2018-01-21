share.initPublications1 = (eventName) ->

  dutiesPublicPolicy = { policy: { $in: ["public", "requireApproval"] } }
  unitPublicPolicy = { policy: { $in: ["public"] } }

  filterForPublic = (userId, sel) =>
    unless share.isManager() #Roles.userIsInRole(userId, 'manager', eventName)
      # getRolesForUser includes all roles, e.g. if user is lead of a department,
      # returns the department and all teams within it
      allOrgUnitIds = Roles.getRolesForUser(Meteor.userId(), eventName)
      sel = _.extend(sel,dutiesPublicPolicy)
      if allOrgUnitIds.length > 0
        sel = { $or: [ parentId: { $in: allOrgUnitIds }, sel ] }
    sel

  # all given a team id, return all signups related to this team
  createPubblicationTeam = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byTeam", (teamId) ->
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
              { find: (duty,signup) ->
                if signup
                  if share.isManagerOrLead(userId,[ signup.parentId ])
                    return Meteor.users.find(signup.userId)
                  else return null
                else return null
              }
            ]
          }
        ]
      }
    )

  createPubblicationTeam("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPubblicationTeam("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPubblicationTeam("LeadSignups",share.LeadSignups,share.Lead)

  # all given a department id, return all teams and all signups related
  # to this department
  createPubblicationDept = (type,signups,duties) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byDepartment", (departmentId) ->
      userId = this.userId
      return {
        find: () -> return share.Team.find({parentId: departmentId})
        children: [
          {
            find: (team) ->
              sel = {parentId: team._id}
              unless share.isManagerOrLead(userId,[ team._id ])
                sel = _.extend(sel,dutiesPublicPolicy)
              return duties.find(sel)
            children: [
              { find: (team, duty) ->
                if share.isManagerOrLead(userId,[ team._id ])
                  return signups.find({parentId: duty._id})
                else return null
                children: [
                  { find: (team,duty,signup) ->
                    if signup
                      if share.isManagerOrLead(userId,[ signup.parentId ])
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

  createPubblicationDept("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPubblicationDept("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPubblicationDept("LeadSignups",share.LeadSignups,share.Lead)

  # given a user id return all signups, shift and teams related to this user
  createPubblicationUser = (type,signups,duties) ->
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

  createPubblicationUser("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPubblicationUser("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPubblicationUser("LeadSignups",share.LeadSignups,share.Lead)

  # given a duty id return the team and all signups related to the current user
  createPubblicationDuty = (type,duties,signups) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byDuty", (id,userId) ->
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
          },
          { find: (duty,signup) ->
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
          }
          { find: (duty,signup) ->
            if signup
              if share.isManagerOrLead(userId,[ signup.parentId ])
                return Meteor.users.find(signup.userId)
              else return null
            else return null
          }
        ]
      }
    )

  createPubblicationDuty("TeamShifts",share.TeamShifts,share.ShiftSignups)
  createPubblicationDuty("TeamTasks",share.TeamTasks,share.TaskSignups)
  createPubblicationDuty("Lead",share.Lead,share.LeadSignups)

  createPubblicationAllDuties = (type,duties) ->
    Meteor.publish "#{eventName}.Volunteers.#{type}", (sel={},limit=10) ->
      sel = dutiesPublicPolicy
      if this.userId
        sel = filterForPublic(this.userId, sel)
      return duties.find(sel,{limit: limit})

  createPubblicationAllDuties("TeamShifts",share.TeamShifts)
  createPubblicationAllDuties("TeamTasks",share.TeamTasks)
  createPubblicationAllDuties("Lead",share.Lead)

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", (sel={}) ->
    if this.userId
      if share.isManagerOrLead(this.userId)
        share.VolunteerForm.find(sel)
      else
        sel = _.extend(sel,{userId: this.userId})
        share.VolunteerForm.find(sel,{fields: {private_notes: 0}})

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
