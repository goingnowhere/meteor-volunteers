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
          duties.find(sel)
        children: [
          { find: (duty) ->
            if share.isManagerOrLead(userId,[ teamId ])
              signups.find({shiftId: duty._id})
            else []
            children: [
              {find: (duty,signup) ->
                if share.isManagerOrLead(userId,[ teamId ])
                  Meteor.users.find(signup.userId)
                else []
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
        find: () -> share.Team.find({parentId: departmentId})
        children: [
          {
            find: (team) ->
              sel = {parentId: team._id}
              unless share.isManagerOrLead(userId,[ team._id ])
                sel = _.extend(sel,dutiesPublicPolicy)
              duties.find(sel)
            children: [
              { find: (team, duty) ->
                if share.isManagerOrLead(userId,[ team._id ])
                  signups.find({shiftId: duty._id})
                else []
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
            console.log             signups.find(sel).fetch()

            signups.find(sel)
          else []
        children: [
          { find: (signup) -> duties.find(signup.shiftId) }
          { find: (signup) -> share.Team.find(signup.parentId) }
        ]
      }
    )

  createPubblicationUser("ShiftSignups",share.ShiftSignups,share.TeamShifts)
  createPubblicationUser("TaskSignups",share.TaskSignups,share.TeamTasks)
  createPubblicationUser("LeadSignups",share.LeadSignups,share.Lead)

  # given a shift id return the team and all signups related to the current user
  createPubblicationShift = (type,duties,signups) ->
    Meteor.publishComposite("#{eventName}.Volunteers.#{type}.byShift", (id,userId) ->
      actualUserId = this.userId
      return {
        find: () -> duties.find(id)
        children: [
          { find: (duty) ->
            if duty
              if userId && (userId == actualUserId) || share.isManagerOrLead(userId, [duty.parentId])
                signups.find({shiftId: duty._id, userId: userId})
              else []
            else []
          },
          { find: (duty) -> if duty then share.Team.find(duty.parentId) else [] }
        ]
      }
    )

  createPubblicationShift("TeamShifts",share.TeamShifts,share.ShiftSignups,[share.Team])
  createPubblicationShift("TeamTasks",share.TeamTasks,share.TaskSignups,[share.Team])
  createPubblicationShift("Lead",share.Lead,[share.Team,share.LeadSignups,share.Department])

  Meteor.publish "#{eventName}.Volunteers.TeamShifts", (sel={},limit=10) ->
    sel = dutiesPublicPolicy
    if this.userId
      sel = filterForPublic(this.userId, sel)
    share.TeamShifts.find(sel,{limit: limit})
