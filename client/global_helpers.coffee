# temporary fix till TAPi18n is compatible with node-simple-schema
Template.registerHelper "_", (p) -> TAPi18n.__ p

Template.registerHelper "formatDateTime",(date) -> moment(date).format("MMMM Do YYYY, h:mm a")
Template.registerHelper "formatDate",(date) -> moment(date).format("MMMM Do YYYY")
Template.registerHelper 'formatTime', (date) -> moment(date).format("h:mm a")
