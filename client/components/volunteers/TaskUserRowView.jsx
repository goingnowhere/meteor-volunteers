import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { T } from '../common/i18n'
import { formatDate } from '../common/dates'

export const TaskUserRowView = ({ team, task }) => (
  <tr>
    <td>{team.name} {task.title}</td>
    <td>
      <FontAwesomeIcon icon="list-check" />
      {formatDate(task.dueDate)} - <T>estimated_time</T> {task.estimatedTime}
    </td>
  </tr>
)

// This isn't currently used anywhere, below is the old coffeescript wiring:
// # this template is called with a taskSignups
// Template.tasksUserRowView.bindI18nNamespace('goingnowhere:volunteers')
// Template.tasksUserRowView.onCreated () ->
//   template = this
//   template.taskSignup = template.data
//   sub = share.templateSub(template,"TasksSignups.byUser", template.taskSignup.userId)

// Template.tasksUserRowView.helpers
//   'team': () -> share.Team.findOne(Template.instance().taskSignup.parentId)
//   'task': () -> collections.task.findOne(Template.instance().taskSignup.shiftId)
