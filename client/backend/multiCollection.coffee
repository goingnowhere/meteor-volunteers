# Template.test.onCreated () ->
#   template = this
#   template.currentLead = new ReactiveVar({add: false})
#   template.subscribe('Volunteers.division')
#
# Template.test.helpers
#   'main': () ->
#     id: "details"
#     label: "details"
#     form: { collection: share.Division }
#     data: share.Division.findOne()
#   'tabs': () -> [{
#     id: "leads"
#     label: "leads"
#     tableFields: [
#       { name: 'userId', template:"leadField"},
#       { name: 'role' }
#     ]
#     form: { collection: share.Lead }
#     subscription : [
#       ((template) -> template.subscribe('Volunteers.users')),
#       ((template) ->
#         template.subscribe('Volunteers.division',() ->
#           id = share.Division.findOne()._id
#           template.subscribe('Volunteers.lead.backend',id))
#         )
#     ]
#     },
#   ]

Template.multiAddView.onCreated () ->
  template = this
  template.currentTabData = new ReactiveDict()
  _.each(template.data.tabs,(t) ->
    template.currentTabData.set(t.id,{add:false})
    _.each(t.subscription, (f) -> f(template))
  )

Template.multiAddView.helpers
  'getTabData': (id) -> Template.instance().currentTabData.get(id)
  'tabVarDict': () -> Template.instance().currentTabData
  'allItems': (collection) -> collection.find()
  'getField': (name,item) -> item[name]

Template.multiAddView.events
  'click [data-action="abandon"]': (event,template) ->
    tabname = $(event.target).data('tabname')
    parentId = template.data.main.data._id
    template.currentTabData.set(tabname,{add: false, teamId: parentId})
  'click [data-action="add"]': (event,template) ->
    tabname = $(event.target).data('tabname')
    parentId = template.data.main.data._id
    visibility = template.data.main.data.visibility
    template.currentTabData.set(tabname,{
      add: true, teamId: parentId, visibility: visibility})
  'click [data-action="delete"]': (event,template) ->
    tabname = $(event.target).data('tabname')
    id = $(event.target).data('id')
    form = _.find(template.data.tabs,(t) -> t.id == tabname).form
    colName = form.collection._name
    methodName =
      if form?.insert?.method
        form.insert.method
      else colName + ".remove"
    Meteor.call methodName, id
  'click [data-action="edit"]': (event,template) ->
    tabname = $(event.target).data('tabname')
    id = $(event.target).data('id')
    tab = _.find(template.data.tabs,(t) -> t.id == tabname)
    collection = tab.form.collection
    data = _.extend(collection.findOne(id),{add: true})
    template.currentTabData.set(tabname,data)
