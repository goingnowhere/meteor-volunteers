
share.form = new ReactiveVar(share.VolunteerForm)
periods =
  'night': {start:'01:00',end: '05:00'},
  'dusk': {start:'05:00',end: '09:00'},
  'morning': {start:'09:00',end: '13:00'},
  'afternoon': {start:'13:00',end: '17:00'},
  'dawn': {start:'17:00',end: '21:00'},
  'evening': {start:'21:00',end: '01:00'}
share.periods = new ReactiveVar(periods)

Volunteers = () ->
  Collections:
    VolunteerForm: share.VolunteerForm
    Teams: share.Teams
    TeamShifts: share.TeamShifts
    TeamTasks: share.TeamTasks
    Shifts: share.Shifts
  Schemas: share.Schemas
  setPeriods: (periods) -> share.periods.set(periods)

Volunteers = new Volunteers()
