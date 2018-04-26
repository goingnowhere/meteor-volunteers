import Moment from 'moment'
import { extendMoment } from 'moment-range'
import { check } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

const moment = extendMoment(Moment)
const share = __coffeescriptShare

share.initServerMethods = (eventName) => {
  const prefix = `${eventName}.Volunteers`
  const getProjectStaffing = new ValidatedMethod({
    name: `${prefix}.getProjectStaffing`,
    validate(projectId) { check(projectId, String) },
    run(projectId) {
      const project = share.Projects.findOne(projectId)
      let days = []
      if (project) {
        const range = moment.range(project.start, project.end).by('days')
        days = Array.from(range)
      }
      const signups =
        share.ProjectSignups.find({ shiftId: projectId }).fetch()

      return days.map(day =>
        signups.filter(signup => signup.status === 'confirmed' &&
          day.isBetween(signup.start, signup.end, 'days', '[]')).length)
    },
  })
}
