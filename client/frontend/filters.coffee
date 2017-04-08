import Flatpickr from 'flatpickr'
import 'flatpickr/dist/flatpickr.css'

Template.daysPicker.onRendered () ->
  opts = { mode: "multiple" }
  new Flatpickr(this.lastNode,opts)

Template.daysPicker.events
  'change #days': ( event, template ) ->
    val = template.$('#range').val()
    range = val.split(' ; ')
    if range.length == 2
      template.data.searchQuery.set('days',range)

Template.rangePicker.onRendered () ->
  opts = { mode: "range" }
  new Flatpickr(this.lastNode,opts)

Template.rangePicker.events
  'change #range': ( event, template ) ->
    val = template.$('#range').val()
    range = val.split(' to ')
    if range.length == 2
      template.data.searchQuery.set('range',range)

Template.periodPicker.onRendered () ->
  data = _.map(_.pairs(share.periods.get()), (v) ->
    s = moment().hour(v[1].start).startOf('hour').format("HH:mm")
    e = moment().hour(v[1].end).endOf('hour').startOf('hour').format("HH:mm")
    {id:v[0], text:"#{s}-#{e}" }
  )
  $("#period").select2({
    data:data,
    multiple: true,
    minimumResultsForSearch: Infinity})

Template.periodPicker.events
  'change #period': ( event, template ) ->
    val = template.$('#period').val()
    template.data.searchQuery.set('period',val)

Template.typePicker.onRendered () ->
  data = _.map(["shift","task","lead"],(t) ->
    id: t
    text: (TAPi18n.__ t))
  $("#type").select2({
    data: data,
    multiple: true})

Template.typePicker.events
  'change #type': ( event, template ) ->
    val = template.$('#type').val()
    template.data.searchQuery.set('types',val)

Template.tagsPicker.onRendered () ->
  template = this
  sub = template.subscribe("Volunteers.teams")
  template.autorun () ->
    if sub.ready()
      data = _.map(share.getTagList(),(t) ->
        id: t.value
        text: t.label)
      $("#tags").select2({
        data: data,
        multiple: true})

Template.tagsPicker.events
  'change #tags': ( event, template ) ->
    val = template.$('#tags').val()
    template.data.searchQuery.set('tags',val)

Template.areasPicker.onRendered () ->
  $("#areas").select2()

Template.areasPicker.events
  'change #areas': ( event, template ) ->
    val = template.$('#areas').val()
    template.data.searchQuery.set('areas',val)
