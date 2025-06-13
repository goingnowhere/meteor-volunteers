import React, {
  useState,
} from 'react'
import Fa from 'react-fontawesome'

import { T, t } from '../common/i18n'
import { Modal } from '../common/Modal.jsx'
import { EarlyEntryList } from './EarlyEntryList.jsx'

/** Button to show a modal listing all early entry volunteers */
export const EarlyEntryModalButton = ({
  deptId,
  teamId,
}) => {
  const [modalOpen, openModal] = useState(false)

  return (
    <>
      <Modal
        title={t('early_entry')}
        isOpen={modalOpen}
        closeModal={() => openModal(false)}
      >
        <EarlyEntryList deptId={deptId} teamId={teamId} />
      </Modal>
      <button
        type="button"
        className="btn btn-light btn-sm d-block"
        onClick={() => openModal(true)}
      >
        <Fa name="file" /> <T>early_entry</T>
      </button>
    </>
  )
}
