import moment from 'moment-timezone'
import { collections } from '../collections/initCollections'

export const isEarlyEntryOpen = () => {
  //TODO get from settings
  const earlyEntryClose = moment('2019-06-12')
  return moment().isBefore(earlyEntryClose)
}

export const areShiftChangesOpen = (dutyType, signup, parentDuty) => {
  if (isEarlyEntryOpen()) {
    return true
  }
  //TODO get from settings
  const eventStart = moment('2019-07-09')

  let startDate
  if (dutyType === 'project') {
    startDate = moment(signup.start)
  } else if (dutyType === 'shift') {
    const duty = parentDuty || collections.dutiesCollections[dutyType].findOne(signup.shiftId)
    startDate = moment(duty && duty.start)
  } else {
    return true
  }
  return startDate.isAfter(eventStart)
}
