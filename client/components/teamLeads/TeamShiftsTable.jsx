import { _ } from 'meteor/underscore'
import React, {
  Fragment,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react'
import { AutoFormComponents } from 'meteor/abate:autoform-components'
import { AutoForm } from 'meteor/aldeed:autoform'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { T, t } from '../common/i18n'
import { Modal } from '../common/Modal.jsx'
import { reactContext } from '../../clientInit'
import { meteorCall } from '../../utils/methodUtils'
import { useMethodCallData } from '../../utils/useMethodCallData'
import { LeadShiftView } from './LeadShiftView.jsx'

// used to display all shifts for a given team
export const TeamShiftsTable = ({
  reloadRef = {},
  date,
  teamId,
  UserInfoComponent,
}) => {
  const Volunteers = useContext(reactContext)
  const { collections, eventName } = Volunteers

  const [{ users, duties }, isLoaded, reloadShifts] = useMethodCallData(
    `${eventName}.Volunteers.getTeamDutyStats`,
    { type: 'shift', teamId, date: date && date.toDate() },
  )
  const shiftGroups = useMemo(() => duties && _.groupBy(duties, 'rotaId'), [duties])

  // Hack to allow reloading from above, remove when adding state management
  useEffect(() => {
    reloadRef.current = reloadShifts
    return () => { reloadRef.current = null }
  }, [reloadShifts, reloadRef])

  const editRota = (rotaId) => {
    meteorCall(Volunteers, 'rotas.findOne', { rotaId }, (_err, rota) => {
      AutoFormComponents.ModalShowWithTemplate('insertUpdateTemplate', {
        form: {
          collection: collections.rotas,
        },
        data: rota,
      }, '', 'lg')
    })
  }
  AutoForm.addHooks([
    'InsertRotasFormId',
    'UpdateRotasFormId',
  ], {
    onSuccess() {
      reloadShifts()
      AutoFormComponents.modalHide()
    },
  })

  const [modalUserId, setModalUserId] = useState('')

  return (
    <table className="table">
      <Modal
        title={t('user_details')}
        isOpen={!!modalUserId}
        closeModal={() => setModalUserId('')}
      >
        <UserInfoComponent userId={modalUserId} />
      </Modal>
      {isLoaded && Object.entries(shiftGroups).map(([rotaId, shifts]) => (
        <Fragment key={rotaId}>
          <thead className="thead-default">
            <tr className="shiftFamily table-active">
              <td colSpan="4"><h5>{shifts[0].title}</h5></td>
              <td>
                <button type="button" className="btn btn-light btn-sm" onClick={() => editRota(rotaId)}>
                  <FontAwesomeIcon icon="pen-to-square" /> <T>edit_group</T>
                </button>
              </td>
              {/* <!--        <td>
                <button type="button" className="btn btn-light btn-sm"
                  data-groupid="{{family.rotaId}}" data-parentid="{{_id}}"
                  data-type="shift" data-action="delete_group">
                  <Fa name="trash-o" /> <T>delete_rota</T>
                </button>
              </td>
      --> */}
            </tr>
          </thead>
          <tbody>
            {shifts.map((shift) => (
              <LeadShiftView
                key={shift._id}
                shift={shift}
                users={users}
                showUserInfo={setModalUserId}
                reload={reloadShifts}
              />
            ))}
          </tbody>
        </Fragment>
      ))}
    </table>
  )
}
