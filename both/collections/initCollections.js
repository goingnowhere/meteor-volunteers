/* globals __coffeescriptShare */
const share = __coffeescriptShare

export const collections = {}
export const schemas = {}

export const initCollections = (eventName) => {
  // shortcut to recover all related collections more easily
  collections.orgUnitCollections = {
    team: share.Team,
    department: share.Department,
    division: share.Division,
  }
  collections.dutiesCollections = {
    lead: share.Lead,
    shift: share.TeamShifts,
    task: share.TeamTasks,
    project: share.Projects,
  }
  collections.signupCollections = {
    lead: share.LeadSignups,
    shift: share.ShiftSignups,
    task: share.TaskSignups,
    project: share.ProjectSignups,
  }
  schemas.signupSchemas = {
    lead: share.Schemas.LeadSignups,
    shift: share.Schemas.ShiftSignups,
    task: share.Schemas.TaskSignups,
    project: share.Schemas.ProjectSignups,
  }
}
