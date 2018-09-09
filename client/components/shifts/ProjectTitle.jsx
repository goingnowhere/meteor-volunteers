import React from 'react'
import Fa from 'react-fontawesome'

export const ProjectTitle = ({ team, title }) => (
  <h5 className="mb-1 mr-auto"><small><Fa name="calendar-o" /> </small>{team.name} &gt; {title}</h5>
)
