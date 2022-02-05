import React from 'react'
import { library } from '@fortawesome/fontawesome-svg-core'
import {
  faArrowsAlt,
  faEdit,
  faPlusSquare,
  faTrashAlt,
  faUserCircle,
  faUserPlus,
} from '@fortawesome/free-solid-svg-icons'
import { faCalendar } from '@fortawesome/free-regular-svg-icons'

export const reactContext = React.createContext()
reactContext.displayName = 'VolunteersInstance'

export function initClient() {
  library.add(
    faArrowsAlt,
    faCalendar,
    faEdit,
    faPlusSquare,
    faTrashAlt,
    faUserCircle,
    faUserPlus,
  )
}
