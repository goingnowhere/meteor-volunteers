
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

Volunteers = () ->
  Collections:
    VolunteerForm: share.VolunteerForm
    Team: share.Team
    Division: share.Division
    Department: share.Department
    TeamShifts: share.TeamShifts
    TeamTasks: share.TeamTasks
    Lead: share.Lead
    Shifts: share.Shifts
  Schemas: share.Schemas
  setPeriods: (periods) -> share.periods.set(periods)

Volunteers = new Volunteers()
