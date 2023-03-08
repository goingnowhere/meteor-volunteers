import React from 'react'
import Fa from 'react-fontawesome'

import { t } from './i18n'

export function NobodiesEmail({ emails }) {
  const email = emails.find((mail) => mail.verified) || emails[0]
  return email.verified ? (
    <span>
      {email.address}
      <span className="text-success"><Fa name='check' /></span>
    </span>
  ) : (
    <span
      title={t('email_not_verified')}
      className="text-danger"
    >
      {email.address}
      <Fa name='warning' />
    </span>
  )
}
