import React from 'react'
import Fa from 'react-fontawesome'

import { __ } from '../common/i18n'

export const ShiftTitle = ({ team, title, priority }) => (
  <div className="row">
    <div className="col">
      <h5 className="mb-1 mr-auto">
        <small><Fa name="calendar" /> </small>
        {team.name} &gt; {title}
        {priority !== 'normal' && (
          <small title={__(priority)} className={priority === 'essential' ? 'text-secondary' : 'text-primary'}>
            <Fa name="exclamation-circle" />
          </small>
        )}
      </h5>
    </div>
    {team.location && (
      <div className="col-md-3">
        <strong>{__('location')}</strong> {team.location}
      </div>
    )}
  </div>
)
