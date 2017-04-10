Template.addDivision.onCreated () ->
  template = this
  template.subscribe('Volunteers.users')
  template.subscribe('Volunteers.division')

Template.addDivision.events
  'click [data-action="removeDivision"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.division.remove", Id

Template.divisionView1.onCreated () ->
  template = this

Template.divisionView1.helpers
  'main': () ->
    id: "details"
    label: "details"
    form: { collection: share.Division }
    data: Template.currentData()
  'tabs': () -> [{
    id: "dept"
    label: "departments"
    tableFields: [ { name: 'name'} ]
    form: { collection: share.Department }
    subscription : [
      ((template) ->
        template.subscribe('Volunteers.division',() ->
          id = share.Division.findOne()._id
          template.subscribe('Volunteers.department.backend',id))
        )
    ]},
    { id: "leads"
    label: "leads"
    tableFields: [
      { name: 'userId', template:"leadField"},
      { name: 'role' }
    ]
    form: { collection: share.Lead }
    subscription : [
      ((template) -> template.subscribe('Volunteers.users')),
      ((template) ->
        template.subscribe('Volunteers.division',() ->
          id = share.Division.findOne()._id
          template.subscribe('Volunteers.lead.backend',id))
        )
    ]
    },
  ]

Template.divisionView.onCreated () ->
  template = this
  sel = {}
  if template.data?._id then sel = {teamId: template.data._id}
  template.currentDept = new ReactiveVar(sel)
  template.currentLead = new ReactiveVar(sel)

Template.divisionView.helpers
  'formDivision': () -> { collection: share.Division }
  'formDept': () -> { collection: share.Department }
  'formLead': () -> { collection: share.Lead }
  'currentDept': () -> Template.instance().currentDept.get()
  'currentLead': () -> Template.instance().currentLead.get()
  'currentDeptVar': () -> Template.instance().currentDept
  'currentLeadVar': () -> Template.instance().currentLead

Template.divisionView.events
  'click [data-action="abandonLead"]': (event,template) ->
    Id = template.data._id
    template.currentLead.set({add: false, teamId: Id})
  'click [data-action="addLead"]': (event,template) ->
    Id = template.data._id
    template.currentLead.set({add: true, teamId: Id})
  'click [data-action="deleteLead"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.lead.remove", Id
  'click [data-action="editLead"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentLead.set(share.Lead.findOne(Id))

  'click [data-action="abandonDept"]': (event,template) ->
    Id = template.data._id
    template.currentDept.set({add: false, teamId: Id})
  'click [data-action="addDept"]': (event,template) ->
    Id = template.data._id
    template.currentDept.set({add: true, teamId: Id})
  'click [data-action="deleteDept"]': (event,template) ->
    Id = $(event.target).data('id')
    Meteor.call "Volunteers.department.remove", Id
  'click [data-action="editDept"]': (event,template) ->
    Id = $(event.target).data('id')
    template.currentDept.set(share.Department.findOne(Id))

# AutoForm.addHooks ['InsertDivisionFormId'],
#   onSuccess: (formType, result) ->
#     router.go ...
