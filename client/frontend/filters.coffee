import Flatpickr from 'flatpickr'
import 'flatpickr/dist/flatpickr.css'

@makeFilter = (searchQuery) ->
  sel = []
  rangeList = searchQuery.get('range')
  if rangeList.length > 0
    range = _.map(rangeList,(d) -> moment(d, 'YYYY-MM-DD'))
    range = moment.range(rangeList)
    sel.push
      $and: [
        {start: { $gte: range.start.startOf('day').toDate() }},
        {start: { $lt: range.end.endOf('day').toDate() }}
      ]
  # console.log "range",sel

  daysList = searchQuery.get('range')
  # if daysList.length > 0
  #   range = _.map(rangeList,(d) -> moment(d, 'YYYY-MM-DD'))
  #   range = moment.range(rangeList)
  #   sel.push
  #     $and: [
  #       {start: { $gte: range.start.toDate() }},
  #       {start: { $lt: range.end.toDate() }}
  #     ]
  # console.log "days",sel

  periodList = searchQuery.get('period')
  if periodList && periodList.length > 0
    periods = share.periods.get()
    for p in periodList
      sel.push
        $and: [
          {startTime: { $gte: periods[p].start }},
          {startTime: { $lt: periods[p].end }}
        ]

  tags = searchQuery.get('tags')
  if tags.length > 0 then sel.push {tags: { $in: tags }}

  types = searchQuery.get('types')
  if types.length > 0 then sel.push {type: { $in: types }}

  areas = searchQuery.get('areas')
  if areas.length > 0 then sel.push {teamId: { $in: areas }}

  return if sel.length > 0 then {"$and": sel} else {}

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
    val = unless val then [] else val
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
    val = unless val then [] else val
    template.data.searchQuery.set('types',val)

Template.tagsPicker.onRendered () ->
  template = this
  sub = template.subscribe("Volunteers.team")
  template.autorun () ->
    if sub.ready()
      tags= template.data.searchQuery.get('tags')
      sel = if tags.length > 0 then {_id: {$in: tags}} else {}
      console.log "tag",sel
      data = _.map(share.getTagList(sel),(t) ->
        id: t.value
        text: t.label)
      $("#tags").select2({
        data: data,
        multiple: true})

Template.tagsPicker.events
  'change #tags': ( event, template ) ->
    val = template.$('#tags').val()
    val = unless val then [] else val
    console.log val
    template.data.searchQuery.set('tags',val)

Template.areasPicker.onRendered () ->
  template = this
  sub = template.subscribe("Volunteers.team")
  template.autorun () ->
    if sub.ready()
      areas = template.data.searchQuery.get('areas')
      sel = if areas.length > 0 then {areas: {$in: areas}} else {}
      areas = share.Team.find(sel).fetch()
      data = _.map(areas,(t) ->
        id: t._id
        text: t.name)
      $("#areas").select2({
        data: data,
        multiple: true})

Template.areasPicker.events
  'change #areas': ( event, template ) ->
    val = template.$('#areas').val()
    val = unless val then [] else val
    template.data.searchQuery.set('areas',val)
