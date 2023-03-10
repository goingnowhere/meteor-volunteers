import React from 'react'
import {
  formatTime,
  formatDateTime,
  isSameDay,
  differenceTime,
} from './dates'

export const ShiftDateInline = ({ start, end }) => (isSameDay(start, end)
  ? <span>{formatDateTime(start)} - {formatTime(end)}</span>
  : <span>{formatDateTime(start)} - {formatTime(end)} {differenceTime(start, end)}</span>
)
