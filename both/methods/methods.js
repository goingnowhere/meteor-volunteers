/* globals __coffeescriptShare */
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line import/no-unresolved

const share = __coffeescriptShare
const moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

export const findConflicts = ({
  userId,
  shiftId,
  start,
  end,
}, collectionKey) => {
  let signupRange
  if (start && end) {
    signupRange = moment.range(start, end)
  } else if (collectionKey === 'ShiftSignups') {
    const parentDoc = share.TeamShifts.findOne({ _id: shiftId })
    signupRange = moment.range(parentDoc.start, parentDoc.end)
  } else {
    return []
  }
  const shiftSignups = share.ShiftSignups.find({
    // it's a double booking only if it is a different shift
    shiftId: { $ne: shiftId },
    userId,
    status: { $in: ['confirmed', 'pending'] },
  }, { shiftId: true }).map(signup => signup.shiftId)
  const projectSignups = share.ProjectSignups.find({
    // it's a double booking only if it is a different shift
    shiftId: { $ne: shiftId },
    userId,
    status: { $in: ['confirmed', 'pending'] },
  }).fetch()
  return [
    ...share.TeamShifts.find({ _id: { $in: shiftSignups } }).fetch(),
    ...projectSignups,
  ].filter(shift => shift && signupRange.overlaps(moment.range(shift.start, shift.end)))
}

export const initMethods = (eventName) => {
  share.initMethods(eventName)
}
