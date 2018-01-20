
share.form = new ReactiveVar(share.VolunteerForm)
periods =
  'night': {start:0,end:4},
  'dawn': {start:4,end:8},
  'morning': {start:8,end:12},
  'afternoon': {start:12,end:16},
  'dusk': {start:16,end:20},
  'evening': {start:20,end:24}
share.periods = new ReactiveVar(periods)

initAuthorization = (eventName) ->
  share.isManager = () ->
    Roles.userIsInRole(Meteor.userId(), [ 'manager', 'admin' ], eventName)
  share.isManagerOrLead = (userId, unitIdList) ->
    if share.isManager() then return true
    else if userId == Meteor.userId()
      Roles.userIsInRole(userId, unitIdList, eventName)
    else return false

saveVolunteerForm = (eventName,data) ->
  Meteor.call('FormBuilder.dynamicForms.upsert',{name: "VolunteerForm"}, data)
  share.extendVolunteerForm({form: data})

class VolunteersClass
  constructor: (@eventName) ->
    share.initCollections(@eventName)
    share.initRouters(@eventName)
    share.initMethods(@eventName)
    initAuthorization(@eventName)
    if Meteor.isServer
      # share.initPublications(@eventName)
      share.initPublications1(@eventName)
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
      LeadSignups: share.LeadSignups
  setPeriods: (periods) -> share.periods.set(periods)
  setUserForm: (data) -> saveVolunteerForm(@eventName,data)
  isManagerOrLead: (userId,unitId) -> share.isManagerOrLead(userId,unitId)
  isManager: () -> share.isManager()
  teamStats: (id) -> share.TeamStats(id)
  deptStats: (id) -> share.DepartmentStats(id)
