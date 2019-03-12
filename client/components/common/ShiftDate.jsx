import React, { Fragment } from 'react'
import {
  formatTime,
  formatDate,
  isSameDay,
  differenceTime,
} from './dates'

export const ShiftDate = ({ start, end }) => (
  <Fragment>
    <div className="col">
      <h5 className="m-0">{formatDate(start)}</h5>
    </div>
    <div className="col">
      <h5 className="m-0">{formatTime(start)} -
        {isSameDay(start, end)
          ? formatTime(end)
          : `${formatTime(end)} ${differenceTime(start, end)}`}
      </h5>
    </div>
  </Fragment>
)
