import { Meteor } from 'meteor/meteor'
import Moment from 'moment'
import { extendMoment } from 'moment-range'
const moment = extendMoment(Moment)
const share = __coffeescriptShare

share.initServerMethods = (eventName) => {
  const prefix = `${eventName}.Volunteers`
  Meteor.methods({
    [`${prefix}.getProjectStaffing`](projectId) {
      const project = share.Projects.findOne(projectId)
      const days = project ? Array.from(moment.range(project.start, project.end).by('days')) : []
      const signups = share.ProjectSignups.find({shiftId: projectId})
        .fetch()

      return days.map(day =>
        signups.filter(signup => signup.status === 'confirmed' && day.isBetween(signup.start, signup.end, 'days', '[]')).length
      )
    }
  })
}
