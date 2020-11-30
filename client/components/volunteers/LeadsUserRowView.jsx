import React from 'react'
import Fa from 'react-fontawesome'

export const LeadsUserRowView = ({ unit, lead }) => (
  <div className="row">
    <div className="col">{unit.name}</div>
    <div className="col"><Fa name="user-circle" /> {lead.title}</div>
  </div>
)

// This isn't currently used anywhere, below is the old coffeescript wiring:
// # this template is called with a leadsSignups
// Template.leadsUserRowView.bindI18nNamespace('goingnowhere:volunteers')
// Template.leadsUserRowView.onCreated () ->
//   template = this
//   template.leadSignup = template.data
//   sub = share.templateSub(template,"LeadsSignups.byUser", template.leadSignup.userId)

// Template.leadsUserRowView.helpers
//   'lead': () -> collections.lead.findOne(Template.instance().leadSignup.shiftId)
//   'unit': () ->
//     parentId = Template.instance().leasSignup.parentId
//     t = share.Team.findOne(parentId)
//     if t then t else
//     dp = share.Department.findOne(parentId)
//     if dp then dp else
//     dv = share.Division.findOne(parentId)
//     if dv then dv else
//     console.log "??? #{parentId}"
