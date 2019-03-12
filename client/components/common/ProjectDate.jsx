import React, { Fragment } from 'react'
import { formatDate, longformDay } from './dates'

export const ProjectDate = ({ start, end }) => (
  <Fragment>
    <div className="col"><h5 className="mb-0">{formatDate(start)}</h5><h6>{longformDay(start)}</h6></div>
    <div className="col"><h5 className="mb-0">{formatDate(end)}</h5><h6>{longformDay(end)}</h6></div>
  </Fragment>
)
