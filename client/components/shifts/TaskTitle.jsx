import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

export const TaskTitle = ({ team, title }) => (
  <h5 className="mb-1 mr-auto"><small><FontAwesomeIcon icon="list-check" /> </small>{team.name} &gt; {title}</h5>
)
