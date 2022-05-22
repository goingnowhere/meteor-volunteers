import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

export const ProjectTitle = ({ team, title }) => (
  <h5 className="mb-1 mr-auto">
    <small><FontAwesomeIcon icon={['far', 'calendar']} /> </small>{team.name} &gt; {title}
  </h5>
)
