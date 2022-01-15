import { library } from '@fortawesome/fontawesome-svg-core'
import {
  faArrowsAlt,
  faEdit,
  faPlusSquare,
  faTrashAlt,
  faUserPlus,
} from '@fortawesome/free-solid-svg-icons'
import { faCalendar } from '@fortawesome/free-regular-svg-icons'

export function initClient() {
  library.add(faArrowsAlt, faCalendar, faEdit, faPlusSquare, faTrashAlt, faUserPlus)
}
