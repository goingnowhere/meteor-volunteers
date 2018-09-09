import React, { Fragment } from 'react'

import { __ } from '../common/i18n'

export const LeadBody = ({
  title,
  description,
  responsibilities,
  qualificatons,
}) => (
  <Fragment>
    <div className="row no-gutters">
      <p className="card-text">
        <strong>{__('title')}: </strong>{title}<br /><br />
        {description}
      </p>
    </div>
    {responsibilities && (
      <div className="row no-gutters">
        <h5 className="mb-2 text-muted">{__('responsibilities')}</h5>
        <p className="card-text"> {responsibilities}</p>
      </div>
    )}
    {qualificatons && (
      <div className="row no-gutters">
        <h5 className="mb-2 text-muted">{__('qualificatons')}</h5>
        <p className="card-text">{qualificatons}</p>
      </div>
    )}
  </Fragment>
)
