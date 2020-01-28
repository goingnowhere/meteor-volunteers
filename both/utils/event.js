import moment from 'moment-timezone'
import { collections } from '../collections/initCollections'

export const isEarlyEntryOpen = () => {
  //TODO get from settings
  const earlyEntryClose = moment('2019-06-12')
  return moment().isBefore(earlyEntryClose)
}

export const areShiftChangesOpen = ({ start, shiftId, type }, parentDuty) => {
  if (isEarlyEntryOpen()) {
    return true
  }
  //TODO get from settings
  const eventStart = moment('2019-07-09')

  let startDate
  if (type === 'project') {
    startDate = moment(start)
  } else if (type === 'shift') {
    const duty = parentDuty || collections.dutiesCollections[type].findOne(shiftId)
    startDate = moment(duty && duty.start)
  } else {
    return true
  }
  return startDate.isAfter(eventStart)
}
