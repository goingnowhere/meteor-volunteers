import React from 'react'
import { formatDate } from './dates'

export const ProjectDateInline = ({ start, end }) => (
  <h6>{formatDate(start) } - {formatDate(end) }</h6>
)
