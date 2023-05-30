import moment from 'moment-timezone'

export const initEventService = (volunteersClass) => {
  const { collections } = volunteersClass

  const isEarlyEntryOpen = () => {
    // TODO Add settings date for when EE changes cannot be made
    const earlyEntryClose = moment('2020-06-10')
    return moment().isBefore(earlyEntryClose)
  }

  return {
    isEarlyEntryOpen,
    areShiftChangesOpen: ({ start, shiftId, type }, parentDuty) => {
      if (isEarlyEntryOpen()) {
        return true
      }
      // TODO get from settings when we no longer have a separate meteor-volunteers module
      const eventStart = moment('2020-07-07')

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
    },
  }
}
