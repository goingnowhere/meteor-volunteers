import React from 'react'
import { formatTime, formatDateTime, isSameDay, differenceTime } from './dates'

export const ShiftDateInline = ({ start, end }) => (isSameDay(start, end)
  ? <h6>{formatDateTime(start)} - {formatTime(end)}</h6>
  : <h6>{formatDateTime(start)} - {formatTime(end)} {differenceTime(start, end)}</h6>
)
