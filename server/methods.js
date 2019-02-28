import { check } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

const share = __coffeescriptShare

const moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

share.initServerMethods = (eventName) => {
  const prefix = `${eventName}.Volunteers`
  const getProjectStaffing = new ValidatedMethod({
    name: `${prefix}.getProjectStaffing`,
    validate(projectId) { check(projectId, String) },
    run(projectId) {
      const project = share.Projects.findOne(projectId)
      if (project) {
        let days = []
        const range = moment.range(project.start, project.end).by('days')
        days = Array.from(range)
        const signups = share.ProjectSignups.find({ shiftId: projectId, status: 'confirmed' }).fetch()

        const confirmed = days.map((day) => {
          const thisday = signups.filter(signup => (day.isBetween(signup.start, signup.end, 'days', '[]')))
          return thisday.length
        })
        return confirmed
      }
      throw new Meteor.Error('InternalError', 'Project not found')
    },
  })
}
