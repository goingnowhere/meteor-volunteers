import { _ } from 'meteor/underscore'

export const userPrefsMatch = (skills, quirks) => ({
  $sum: [
    { $size: { $ifNull: [{ $setIntersection: [quirks, '$quirks'] }, []] } },
    { $size: { $ifNull: [{ $setIntersection: [skills, '$skills'] }, []] } },
  ],
})

export const dutyPriorityScore = {
  $cond: [{ $eq: ['$priority', 'normal'] }, 1,
    {
      $cond: [{ $eq: ['$priority', 'important'] }, 2,
        {
          $cond: [{ $eq: ['$priority', 'essential'] }, 3, 1],
        },
      ],
    },
  ],
}

export const initCollectionUtils = (collections) => ({
  getSkillsList: (sel = {}) =>
    _.union(...collections.team.find(sel, { fields: { skills: true } })
      .map(team => team.skills))
      .filter(item => item)
      .map(tag => ({ value: tag, label: tag })),

  getQuirksList: (sel = {}) =>
    _.union(...collections.team.find(sel, { fields: { quirks: true } })
      .map(team => team.quirks))
      .filter(item => item)
      .map(tag => ({ value: tag, label: tag })),

  getLocationList: (sel = {}) =>
    _.union(...collections.team.find(sel, { fields: { location: true } })
      .map(team => team.location))
      .filter(item => item)
      .map(loc => ({ value: loc, label: loc })),

  findOrgUnit: (unitId) => {
    const team = collections.team.findOne({ _id: unitId })
    if (team) {
      return {
        unit: team,
        type: 'team',
      }
    }
    const dept = collections.department.findOne({ _id: unitId })
    if (dept) {
      return {
        unit: dept,
        type: 'department',
      }
    }
    const div = collections.division.findOne({ _id: unitId })
    if (div) {
      return {
        unit: div,
        type: 'division',
      }
    }
    return {}
  },
})
