import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { t } from '../common/i18n'

export const ProjectTitle = ({ team, title, priority = 'normal' }) => (
  <h5 className="mb-1 mr-auto">
    <small><FontAwesomeIcon icon="calendar-week" /> </small>
    {team.name} &gt; {title}
    {priority !== 'normal' && (
      <small title={t(priority)} className={priority === 'essential' ? 'text-secondary' : 'text-primary'}>
        <FontAwesomeIcon icon="exclamation-circle" />
      </small>
    )}
  </h5>
)
