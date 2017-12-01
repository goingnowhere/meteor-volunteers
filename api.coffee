toShare = {}

toShare.form = new ReactiveVar(share.VolunteerForm)
periods =
  'night': {start:0,end:4},
  'dawn': {start:4,end:8},
  'morning': {start:8,end:12},
  'afternoon': {start:12,end:16},
  'dusk': {start:16,end:20},
  'evening': {start:20,end:24}
toShare.periods = new ReactiveVar(periods)

# XXX why do I need this variable ???
toShare.eventName1 = new ReactiveVar()

initAuthorization = (eventName) ->
  toShare.isManagerOrLead = (userId) ->
    if Roles.userIsInRole(userId, [ 'manager' ], eventName)
      return true
    else if userId == Meteor.userId()
      Roles.getRolesForUser(userId, eventName).length > 0
    else return false
  toShare.isManager = (userId) ->
    Roles.userIsInRole(userId, [ 'manager' ], eventName)
  module.exports = toShare
  _.extend(share, toShare)

saveVolunteerForm = (eventName,data) ->
  Meteor.call('FormBuilder.dynamicForms.upsert',{name: "VolunteerForm"}, data)
  share.extendVolunteerForm({form: data})

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
    toShare.eventName1.set(@eventName)
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
  setPeriods: (periods) -> toShare.periods.set(periods)
  setUserForm: (data) -> saveVolunteerForm(@eventName,data)
  isManagerOrLead: (userId) -> toShare.isManagerOrLead(userId)
  isManager: (userId) -> toShare.isManager(userId)

module.exports = toShare
_.extend(share, toShare)
