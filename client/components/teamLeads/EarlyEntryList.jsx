import React, {
  useContext,
} from 'react'

import { T } from '../common/i18n'
import { reactContext } from '../../clientInit'
import { useMethodCallData } from '../../utils/useMethodCallData'
import { Loading } from '../common/Loading'

/** List all early entry volunteers */
export const EarlyEntryList = ({
  deptId,
  teamId,
}) => {
  // const Volunteers = useContext(reactContext)

  const [oldEE, oldIsLoaded] = useMethodCallData(
    'ee.csv',
    { parentId: deptId },
  )
  const [{ volList, eeList, newEE }, isLoaded] = useMethodCallData(
    'duties.earlyEntry.list',
    { teamId, deptId },
  )
  console.log('EE!', { newEE, oldEE }, { volList, eeList })

  return (
    <>
      {!isLoaded ? <Loading /> : (
        <table className="table">
          <thead>
            <th><T>name</T></th>
            <th><T>email</T></th>
            <th><T>ticket_number</T></th>
            <th><T>arrival_date</T></th>
            <th><T>team</T></th>
          </thead>
          <tbody>
            {newEE.map((ee) => (
              <tr key={ee.userId}>
                <td>{ee.name}</td>
                <td>{ee.email}</td>
                <td>{ee.ticket}</td>
                <td>{ee.eeDate}</td>
                <td>{ee.team}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      {!oldIsLoaded ? <Loading /> : (
        <table className="table">
          <thead>
            <th><T>name</T></th>
            <th><T>email</T></th>
            <th><T>ticket_number</T></th>
            <th><T>arrival_date</T></th>
            <th><T>team</T></th>
          </thead>
          <tbody>
            {oldEE.map((ee) => (
              <tr key={ee.userId}>
                <td>{ee.name}</td>
                <td>{ee.email}</td>
                <td>{ee.ticket}</td>
                <td>{ee.eeDate}</td>
                <td>{ee.team}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </>
  )
}
