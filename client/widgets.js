
Template.progressBarShifts.helpers({
  value() {
    const { max, confirmed } = Template.currentData()
    const value = Math.floor((confirmed / max) * 100)
    return value
  },
})
