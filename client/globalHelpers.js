import { Template } from 'meteor/templating'
import { formatDate, formatDateTime } from './components/common/dates'

// It looks like this is used in meteor-user-profiles
Template.registerHelper('formatDateTime', formatDateTime)
// Still used for now in volunteers-nowhere
Template.registerHelper('formatDate', formatDate)
