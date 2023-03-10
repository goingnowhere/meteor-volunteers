import React from 'react'
import { formatDate } from './dates'

export const ProjectDateInline = ({ start, end }) => (
  <span>{formatDate(start) } - {formatDate(end) }</span>
)
