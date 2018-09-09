import React from 'react'
import Fa from 'react-fontawesome'

export const LeadTitle = ({ team }) => (
  <h5 className="mb-1 mr-auto"><small><Fa name="user-circle" /> </small>{team.name}</h5>
)
