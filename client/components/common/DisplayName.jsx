import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { t } from './i18n'
import { displayName } from '../../../both/utils/helpers'

export const getDisplayNameFromList = (users, userId, onClick) => {
  const user = users?.find((usr) => usr._id === userId)
  return user && (
    <DisplayName
      onClick={onClick}
      user={user}
      flagTicket
    />
  )
}

const Outer = ({
  onClick,
  children,
  className,
  ...rest
}) => (onClick ? (
  <button onClick={onClick} type="button" className={`${className} btn btn-link`} {...rest}>
    {children}
  </button>
) : (
  <span className={className} {...rest}>{children}</span>
))
export function DisplayName({ user, flagTicket, onClick }) {
  const props = flagTicket && !user.ticketId ? {
    className: 'text-danger',
    title: t('no_ticket'),
    onClick,
  } : {
    onClick,
  }
  return (
    <Outer {...props}>
      {displayName(user)}
      {flagTicket && !user.ticketId && (
        <span className="fa-layers fa-fw fa-lg">
          <FontAwesomeIcon icon="ticket" className="text-body" transform="shrink-6" />
          <FontAwesomeIcon icon="xmark" />
        </span>
      )}
    </Outer>
  )
}
