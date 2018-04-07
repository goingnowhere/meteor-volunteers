Template.registerHelper "formatDateTime",(date) -> moment(date).format("MMM Do, HH:mm")
Template.registerHelper "formatDate",(date) -> moment(date).format("MMM Do (ddd)")
Template.registerHelper 'formatTime', (date) -> moment(date).format("HH:mm")
Template.registerHelper 'differenceTime', (start,end) -> "(+#{moment(end).diff(start,'days')+1})"
