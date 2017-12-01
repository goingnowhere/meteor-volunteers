toShare = {}
toShare.initPublications = (eventName) ->

  dutiesPublicPolicy = { policy: { $in: ["public", "requireApproval"] } }
  unitPublicPolicy = { policy: { $in: ["public"] } }

  filterForPublic = (userId, sel) =>
    unless Roles.userIsInRole(userId, 'manager', eventName)
      # getRolesForUser includes all roles, e.g. if user is lead of a department,
      # returns the department and all teams within it
      allOrgUnitIds = Roles.getRolesForUser(Meteor.userId(), eventName)
      sel = _.extend(sel,dutiesPublicPolicy)
      if allOrgUnitIds.length > 0
        sel = { $or: [ parentId: { $in: allOrgUnitIds }, sel ] }
    sel

  Meteor.publish "#{eventName}.Volunteers.team", (sel={}) ->
    if this.userId
      if share.isManagerOrLead(this.userId)
        share.Team.find(sel)
      else
        share.Team.find(_.extend(sel,unitPublicPolicy))

  Meteor.publish "#{eventName}.Volunteers.division", () ->
    if this.userId
      if share.isManagerOrLead(this.userId)
        share.Division.find()
      else
        share.Division.find(unitPublicPolicy)

  Meteor.publish "#{eventName}.Volunteers.department", () ->
    if this.userId
      if share.isManagerOrLead(this.userId)
        share.Department.find()
      else
        share.Department.find(unitPublicPolicy)

  Meteor.publish "#{eventName}.Volunteers.organization", () ->
    sel = {}
    unless (not this.userId) || share.isManagerOrLead(this.userId)
      sel = unitPublicPolicy
    dp = share.Department.find(sel)
    t = share.Team.find(sel)
    dv = share.Division.find(sel)
    [dv,dp,t]

  Meteor.publish "#{eventName}.Volunteers.teamShifts", (sel={},limit=1) ->
    if this.userId
      sel = filterForPublic(this.userId, sel)
      share.TeamShifts.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.teamTasks", (sel={},limit=1) ->
    if this.userId
      sel = filterForPublic(this.userId, sel)
      share.TeamTasks.find(sel,{limit: limit})

  Meteor.publish "#{eventName}.Volunteers.lead", (sel={},limit=1) ->
    if this.userId
      sel = filterForPublic(this.userId, sel)
      share.Lead.find(sel)

  Meteor.publish "#{eventName}.Volunteers.allDuties", (sel={},limit=1) ->
    # XXX sel can contain only a number of filters. I should checked
    # what we pass this this funtion. We can use the module 'check' to
    # do this by providing an object like simpleschema. This should be
    # done whenever we accept an input from the outside
    if this.userId
      sel = filterForPublic(this.userId, sel)
      s = share.TeamShifts.find(sel,{limit: limit / 3})
      t = share.TeamTasks.find(sel,{limit: limit / 3})
      l = share.Lead.find(sel,{limit: limit / 3})
      selTeam = _.clone(sel)
      selTeam = _.extend(selTeam,unitPublicPolicy) unless share.isManagerOrLead(this.userId)
      tt = share.Team.find(selTeam)
      d = share.Department.find()
      dd = share.Division.find()
      [s,t,l,tt,d,dd]

  Meteor.publish "#{eventName}.Volunteers.allDuties.byTeam", (teamId) ->
    if this.userId
      selShifts = {parentId: teamId}
      selTasks = {parentId: teamId}
      unless Roles.userIsInRole(this.userId, [ 'manager', teamId ], eventName)
        selTasks = _.extend(selTasks,dutiesPublicPolicy)
        selShifts = dutiesPublicPolicy
      taskSignups = share.TaskSignups.find({parentId: teamId})
      shiftSignups = share.ShiftSignups.find({parentId: teamId})
      leadSignups = share.LeadSignups.find({parentId: teamId})
      shifts = share.TeamShifts.find(selShifts)
      tasks = share.TeamTasks.find(selTasks)
      leads = share.Lead.find({parentId: teamId})
      teams = share.Team.find({_id: teamId})
      # XXX: restrict to dept and div related to this team ...
      team = share.Team.findOne(teamId)
      d = share.Department.find(team.parentId)
      department = share.Department.findOne(team.parentId)
      dd = share.Division.find(department.parentId)
      [taskSignups,shiftSignups,leadSignups,shifts,tasks,leads,teams,d,dd]

  Meteor.publish "#{eventName}.Volunteers.allDuties.byUser", () ->
    if this.userId
      # sel.policy = {$in: ["requireApproval","public"]}
      # if Roles.userIsInRole(this.userId, [ 'manager' ]) then delete sel.policy
      tasks = share.TaskSignups.find({userId: this.userId, status: {$in: ["confirmed", "pending","refused"]}})
      shifts = share.ShiftSignups.find({userId: this.userId, status: {$in: ["confirmed", "pending","refused"]}})
      shiftIds = shifts.map((e) -> e.shiftId).concat(tasks.map((e) -> e.shiftId))
      teamIds = shifts.map((e) -> e.teamId).concat(tasks.map((e) -> e.teamId))
      s = share.TeamShifts.find({_id: {$in: shiftIds}})
      t = share.TeamTasks.find({_id: {$in: shiftIds}})
      l = share.Lead.find({parentId: {$in: teamIds}})
      tt = share.Team.find({_id: {$in: teamIds}})
      d = share.Department.find()
      dd = share.Division.find()
      [tasks,shifts,s,t,l,tt,d,dd]

# XXX if these are not used anymore, we can remove this chunk of code
  # ^^ (You were referring to the next 3 publications) but they do seem to be used
  # so I'm uncommenting them - Rich
  Meteor.publish "#{eventName}.Volunteers.teamShifts.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.TeamShifts.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.teamTasks.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.TeamTasks.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.lead.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.Lead.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.department.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.Department.find({parentId: id})

  Meteor.publish "#{eventName}.Volunteers.team.backend", (id) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", id ], eventName)
        share.Team.find({parentId: id})

  signupCollections = [share.ShiftSignups, share.TaskSignups, share.LeadSignups]

  Meteor.publish "#{eventName}.Volunteers.signups.byShift", (shiftId) ->
    if this.userId
      teamId = signupCollections.reduce(((lastId, col) =>
        lastId || col.findOne({ _id: shiftId })?.parentId), null)
      if Roles.userIsInRole(this.userId, [ "manager", teamId ], eventName)
        sel = {shiftId: shiftId}
      else
        sel = {userId: this.userId, shiftId: shiftId}
      signupCollections.map((col) => col.find(sel))

  Meteor.publish "#{eventName}.Volunteers.signups.byTeam", (parentId) ->
    if this.userId
      if Roles.userIsInRole(this.userId, [ "manager", parentId ], eventName)
        sel = {parentId: parentId}
      else
        sel = {userId: this.userId, parentId: parentId}
      return signupCollections.map((col) => col.find(sel))

  Meteor.publish "#{eventName}.Volunteers.teamShiftsUser", () ->
    if this.userId
      l = share.ShiftSignups.find({userId: this.userId}).map((e) -> e._id)
      share.TeamShifts.find({_id: {$in: l}})

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", () ->
    if this.userId
      if share.isManagerOrLead(this.userId)
        share.VolunteerForm.find()
      else
        share.VolunteerForm.find({userId: this.userId})

  Meteor.publish "#{eventName}.Volunteers.users", () ->
    if this.userId
      if share.isManagerOrLead(this.userId)
        Meteor.users.find({}, { fields: { emails: 1, profile: 1, roles: 1 } })

module.exports = toShare
_.extend(share, toShare)
