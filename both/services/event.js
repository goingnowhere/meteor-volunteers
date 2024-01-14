import moment from 'moment-timezone'

export const initEventService = (volunteersClass) => {
  const { collections, settings } = volunteersClass

  const service = {
    isEarlyShift: ({ start }) => {
      // Can't do this in parent as it doesn't autorun on client
      const eeEnd = moment(settings.get()?.eventPeriod?.start).add(1, 'day')
      return eeEnd.isAfter(start)
    },
    areShiftChangesOpen: (signup, parentDuty) => {
      const { start, shiftId, type } = signup
      let startDate
      if (type === 'project') {
        startDate = moment(start)
      } else if (type === 'shift') {
        const duty = parentDuty || collections.dutiesCollections[type].findOne(shiftId)
        startDate = moment(duty && duty.start)
      } else {
        return true
      }

      if (service.isEarlyShift({ start: startDate })) {
        const earlyEntryClose = moment(settings.get()?.earlyEntryClose)
        return earlyEntryClose.isAfter()
      }

      const eventPeriod = settings.get()?.eventPeriod
      return !eventPeriod
        || moment(eventPeriod.start).isAfter()
        || startDate.isAfter(eventPeriod.end)
    },
  }
  return service
}
