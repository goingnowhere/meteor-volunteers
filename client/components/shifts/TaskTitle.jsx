import React from 'react'
import Fa from 'react-fontawesome'

export const TaskTitle = ({ team, title }) => (
  <h5 className="mb-1 mr-auto"><small><Fa name="tasks" /> </small>{team.name} &gt; {title}</h5>
)
