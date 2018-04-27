import Moment from 'moment'
import 'moment-timezone'
import { extendMoment } from 'moment-range'

moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

Template.registerHelper "formatDateTime",(date) -> moment(date).format("MMM Do, HH:mm")
Template.registerHelper "formatDate",(date) -> moment(date).format("MMM Do (ddd)")
Template.registerHelper 'formatTime', (date) -> moment(date).format("HH:mm")
Template.registerHelper 'differenceTime', (start,end) -> "(+#{moment(end).diff(start,'days')+1})"
