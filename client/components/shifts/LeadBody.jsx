import React, { Fragment } from 'react'

import { T } from '../common/i18n'

export const LeadBody = ({
  title,
  description,
  responsibilities,
  qualificatons,
}) => (
  <Fragment>
    <div className="row no-gutters">
      <p className="card-text">
        <strong><T>title</T>: </strong>{title}<br /><br />
        {description}
      </p>
    </div>
    {responsibilities && (
      <div className="row no-gutters">
        <h5 className="mb-2 text-muted"><T>responsibilities</T></h5>
        <p className="card-text"> {responsibilities}</p>
      </div>
    )}
    {qualificatons && (
      <div className="row no-gutters">
        <h5 className="mb-2 text-muted"><T>qualificatons</T></h5>
        <p className="card-text">{qualificatons}</p>
      </div>
    )}
  </Fragment>
)
