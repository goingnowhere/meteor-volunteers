Template.registerHelper "formatDateTime",(date) -> moment(date).format("MMM Do, H:mm")
Template.registerHelper "formatDate",(date) -> moment(date).format("MMM Do")
Template.registerHelper "formatMoment",(date, format) -> moment(date).format(format)
Template.registerHelper 'formatTime', (date) -> moment(date).format("H:mm")
Template.registerHelper 'differenceTime', (start,end) -> "(+#{moment(end).diff(start,'days')+1})"
