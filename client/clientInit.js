import React from 'react'
import { library } from '@fortawesome/fontawesome-svg-core'
import {
  faArrowsAlt,
  faCalendarWeek,
  faCheck,
  faClock,
  faExclamationCircle,
  faEdit,
  faListCheck,
  faLock,
  faPenToSquare,
  faPeoplePulling,
  faPlusSquare,
  faTrashAlt,
  faTriangleExclamation,
  faUserCircle,
  faUserPlus,
  faUserSecret,
} from '@fortawesome/free-solid-svg-icons'
// We don't actually use this for now
// import { faCalendar } from '@fortawesome/free-regular-svg-icons'

export const reactContext = React.createContext()
reactContext.displayName = 'VolunteersInstance'

export function initClient() {
  library.add(
    faArrowsAlt,
    // faCalendar,
    faCalendarWeek,
    faCheck,
    faClock,
    faExclamationCircle,
    faEdit,
    faListCheck,
    faLock,
    faPenToSquare,
    faPeoplePulling,
    faPlusSquare,
    faTrashAlt,
    faTriangleExclamation,
    faUserCircle,
    faUserPlus,
    faUserSecret,
  )
}
