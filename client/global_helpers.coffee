Template.registerHelper "formatDateTime",(date) -> moment(date).format("MMM Do, h:mm a")
Template.registerHelper "formatDate",(date) -> moment(date).format("MMM Do")
Template.registerHelper 'formatTime', (date) -> moment(date).format("h:mm a")
Template.registerHelper 'differenceTime', (start,end) -> "(+#{moment(end).diff(start,'days')})"
