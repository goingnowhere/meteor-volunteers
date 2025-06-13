import moment from 'moment-timezone'

export const initEventService = (volunteersClass) => {
  const { collections, settings } = volunteersClass

  const service = {
    isEarlyShift: ({ start }) => {
      // Can't do this in parent as it doesn't autorun on client
      const eeReqEnd = settings.get()?.earlyEntryRequirementEnd
      const eeEnd = eeReqEnd ? moment(eeReqEnd) : moment(settings.get()?.eventPeriod?.start).add(1, 'day')
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
      const now = moment()

      if (service.isEarlyShift({ start: startDate })) {
        const earlyEntryClose = settings.get()?.earlyEntryClose
        return !earlyEntryClose || now.isBefore(earlyEntryClose)
      }

      return now.isBefore(startDate)
    },
  }
  return service
}
