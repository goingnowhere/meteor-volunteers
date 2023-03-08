import React from 'react'
import Fa from 'react-fontawesome'
import { displayName } from 'meteor/goingnowhere:volunteers'

import { T, t } from './i18n'
import { formatDateTime } from './dates'
import { NobodiesEmail } from './NobodiesEmail.jsx'

function InfoItem({ title, children }) {
  return (
    <>
      <dt className="col-sm-3">{title}</dt>
      <dd className="col-sm-9">{children}</dd>
    </>
  )
}

export function UserInfoList({ user }) {
  const {
    status,
    emails,
    ticketId,
    createdAt,
    fistRoles,
  } = user
  return (
    <dl className="row">
      <InfoItem title={t('name')}>{displayName(user)}</InfoItem>
      <InfoItem title={t('real_name')}>{user.profile.firstName} {user.profile.lastName}</InfoItem>
      <InfoItem title={t('ticket_number')}>
        {ticketId || (<span className="text-danger"><T>no_ticket</T></span>)}
      </InfoItem>
      {emails && (
        <InfoItem title={t('email')}>
          <NobodiesEmail emails={emails} />
        </InfoItem>
      )}
      <InfoItem title={t('created')}>{formatDateTime(createdAt)}</InfoItem>
      {status?.lastLogin && (
        <InfoItem title={t('last_login')}>
          {formatDateTime(status.lastLogin.date)}
        </InfoItem>
      )}
      {fistRoles?.length > 0 && (
        <InfoItem title={t('site_roles')}>
          {fistRoles.map(fistRole => (
            <span key={fistRole} className="badge badge-pill badge-light">{fistRole}</span>
          ))}
        </InfoItem>
      )}
    </dl>
  )
}
