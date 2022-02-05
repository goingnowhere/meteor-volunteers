import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

export const LeadTitle = ({ team }) => (
  <h5 className="mb-1 mr-auto"><small><FontAwesomeIcon icon="user-circle" /></small>{team.name}</h5>
)
