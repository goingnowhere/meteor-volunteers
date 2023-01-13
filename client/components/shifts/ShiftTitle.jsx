import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { t, T } from '../common/i18n'

export const ShiftTitle = ({ team, title, priority }) => (
  <div className="row">
    <div className="col">
      <h5 className="mb-1 mr-auto">
        <small><FontAwesomeIcon icon="clock" /> </small>
        {team.name} &gt; {title}
        {priority !== 'normal' && (
          <small title={t(priority)} className={priority === 'essential' ? 'text-secondary' : 'text-primary'}>
            <FontAwesomeIcon icon="exclamation-circle" />
          </small>
        )}
      </h5>
    </div>
    {team.location && (
      <div className="col-md-3">
        <strong><T>location</T></strong> {team.location}
      </div>
    )}
  </div>
)
