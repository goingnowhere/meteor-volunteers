import { Template } from 'meteor/templating'
import { AutoForm } from 'meteor/aldeed:autoform'
import { ProjectStaffingInput } from '../components/shifts/ProjectStaffingInput'

// This is a weird hack and means we can't have more than one, but we want to get rid of
// the autoform Blaze magic anyway
let dangerousVar

Template.projectStaffingInput.bindI18nNamespace('goingnowhere:volunteers')
Template.projectStaffingInput.helpers({
  ProjectStaffingInput: () => ProjectStaffingInput,
  // Putting these in useTracker in React seemed problematic, so do it here instead
  start: () => AutoForm.getFieldValue('start'),
  end: () => AutoForm.getFieldValue('end'),
  staffing: () => AutoForm.getFieldValue('staffing'),
  callback: () => (arg) => dangerousVar = arg,
})
AutoForm.addInputType("projectStaffing", {
  template: 'projectStaffingInput',
  valueIn: (valIn) => {
    if (!dangerousVar) {
      dangerousVar = valIn
    }
    return valIn
  },
  valueOut: () => dangerousVar,
})
