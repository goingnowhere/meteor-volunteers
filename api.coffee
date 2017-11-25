
share.form = new ReactiveVar(share.VolunteerForm)
periods =
  'night': {start:0,end:4},
  'dusk': {start:4,end:8},
  'morning': {start:8,end:12},
  'afternoon': {start:12,end:16},
  'dawn': {start:16,end:20},
  'evening': {start:20,end:24}
share.periods = new ReactiveVar(periods)

share.roles = new ReactiveVar(["lead","co-lead"])
# XXX why do I need this variable ???
share.eventName1 = new ReactiveVar()

initAuthorization = (eventName) ->
  share.isManagerOrLead = (userId) ->
    allOrgUnitIds = Roles.getRolesForUser(Meteor.userId(), eventName)
    Roles.userIsInRole(userId, 'manager', eventName) || allOrgUnitIds.length > 0

class VolunteersClass
  constructor: (@eventName) ->
    # XXX this is a nasty side effect. I initialize these collecions,
    # I make them available thought global variables (share.xxx) and
    # and then I use them all over the places in this package.
    # in theory there should be any leak in the global name space of the
    # parent application as everythin is relative to this module
    share.initCollections(@eventName)
    share.initRouters(@eventName)
    share.initMethods(@eventName)
    share.eventName1.set(@eventName)
    initAuthorization(@eventName)
    if Meteor.isServer
      share.initPublications(@eventName)
    @Schemas = share.Schemas
    @Collections =
      VolunteerForm: share.VolunteerForm
      Team: share.Team
      Division: share.Division
      Department: share.Department
      TeamShifts: share.TeamShifts
      TeamTasks: share.TeamTasks
      Lead: share.Lead
      ShiftSignups: share.ShiftSignups
      TaskSignups: share.TaskSignups
  setPeriods: (periods) -> share.periods.set(periods)
  isManagerOrLead: (userId) -> share.isManagerOrLead(userId)
