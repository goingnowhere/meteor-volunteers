import React, { Fragment } from 'react'
import { ShiftTitle } from './ShiftTitle.jsx'
import { TaskTitle } from './TaskTitle.jsx'
import { ProjectTitle } from './ProjectTitle.jsx'
import { DutyBody } from './DutyBody.jsx'

const DutiesListItemTitle = ({
  type,
  team,
  title,
  priority,
}) => {
  if (type === 'shift') {
    return <ShiftTitle team={team} title={title} priority={priority} />
  }
  if (type === 'task') {
    return <TaskTitle team={team} title={title} />
  }
  if (type === 'project') {
    return <ProjectTitle team={team} title={title} />
  }
  return null
}

const DutiesListItemContent = ({ description, team }) => (
  <Fragment>
    <div className="row no-gutters">
      <DutyBody description={description} />
    </div>
    <div className="row no-gutters">
      {!(team.quirks && team.skills) ? null : (
        <ul className="list-inline my-1">
          {team.skills.map(skill => (
            <li key={skill} className="list-inline-item">
              <span className="badge badge-secondary badge-pill">{skill}</span>
            </li>
          ))}
          {team.quirks.map(quirk => (
            <li key={quirk} className="list-inline-item">
              <span className="badge badge-primary badge-pill">{quirk}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  </Fragment>
)

export const DutiesListItem = ({ duty }) => (
  <Fragment>
    <DutiesListItemTitle {...duty} />
    <DutiesListItemContent {...duty} />
  </Fragment>
)
