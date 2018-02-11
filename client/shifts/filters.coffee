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
    val = unless val then [] else val
    template.data.searchQuery.set('period',val)

Template.dutiesPicker.onRendered () ->
  data = _.map(["shift","task","lead"],(t) ->
    id: t
    text: (i18n.__("abate:volunteers",t)))
  $("#duties").select2({
    data: data,
    multiple: true})

Template.dutiesPicker.events
  'change #duties': ( event, template ) ->
    val = template.$('#duties').val()
    val = unless val then [] else val
    template.data.searchQuery.set('duties',val)

Template.tagsPicker.onRendered () ->
  template = this
  sub = share.templateSub(template,"team")
  template.autorun () ->
    if sub.ready()
      tags= template.data.searchQuery.get('tags')
      sel = if tags?.length > 0 then {_id: {$in: tags}} else {}
      data = _.map(share.getSkillsList(sel),(t) ->
        id: t.value
        text: t.label)
      $("#tags").select2({
        data: data,
        multiple: true})

Template.tagsPicker.events
  'change #tags': ( event, template ) ->
    val = template.$('#tags').val()
    val = unless val then [] else val
    template.data.searchQuery.set('tags',val)

Template.teamsPicker.onRendered () ->
  template = this
  sub = share.templateSub(template,"team")
  template.autorun () ->
    if sub.ready()
      teams = template.data.searchQuery.get('teams')
      sel = if teams?.length > 0 then {_id: {$in: teams}} else {}
      units = share.Team.find(sel).fetch()
      data = _.map(units,(t) ->
        id: t._id
        text: t.name)
      $("#teams").select2({
        data: data,
        multiple: true})

Template.teamsPicker.events
  'change #teams': ( event, template ) ->
    val = template.$('#teams').val()
    val = unless val then [] else val
    template.data.searchQuery.set('teams',val)

# XXX to be refactor with teams and divisoion picker
Template.departmentsPicker.onRendered () ->
  template = this
  sub = share.templateSub(template,"department")
  template.autorun () ->
    if sub.ready()
      departments = template.data.searchQuery.get('departments')
      sel = if departments?.length > 0 then {_id: {$in: departments}} else {}
      units = share.Department.find(sel).fetch()
      data = _.map(units,(t) ->
        id: t._id
        text: t.name)
      $("#departments").select2({
        data: data,
        multiple: true})

Template.departmentsPicker.events
  'change #departments': ( event, template ) ->
    val = template.$('#departments').val()
    val = unless val then [] else val
    template.data.searchQuery.set('departments',val)
