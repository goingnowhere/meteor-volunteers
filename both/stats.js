/* globals __coffeescriptShare */
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line import/no-unresolved, import/extensions

const share = __coffeescriptShare
const moment = extendMoment(Moment)

export const projectSignupsConfirmed = (p) => {
  const pdays = Array.from(moment.range(moment(p.start), moment(p.end)).by('day'))
  const dayStrings = pdays.map(m => m.toISOString())
  const needed = new Map(dayStrings.map((day, i) => [day, p.staffing[i].min]))
  const wanted = new Map(dayStrings.map((day, i) => [day, p.staffing[i].max]))
  const confirmed = new Map(dayStrings.map(day => [day, 0]))
  const signups = share.ProjectSignups.find({ shiftId: p._id, status: 'confirmed' }).fetch()
  signups.forEach((signup) => {
    pdays.forEach((day) => {
      const dayString = day.toISOString()
      if (day.isBetween(signup.start, signup.end, 'days', '[]')) {
        confirmed.set(dayString, confirmed.get(dayString) + 1)
        needed.set(dayString, needed.get(dayString) - 1)
        wanted.set(dayString, wanted.get(dayString) - 1)
      }
    })
  })
  return {
    needed: Array.from(needed.values()),
    wanted: Array.from(wanted.values()),
    confirmed: Array.from(confirmed.values()),
    days: dayStrings,
  }
}
