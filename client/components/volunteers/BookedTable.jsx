import React, { useContext, useState } from 'react'
import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'

import { reactContext } from '../../clientInit'
import { Modal } from '../common/Modal.jsx'
import { ProjectSignupForm } from '../shifts/ProjectSignupForm.jsx'
import { SignupUserRowView } from './SignupUserRowView.jsx'

export const BookedTable = ({
  userId,
}) => {
  const Volunteers = useContext(reactContext)
  const { collections, eventName } = Volunteers

  const allShifts = useTracker(() => {
    const bookedUserId = userId || Meteor.userId()
    Meteor.subscribe(`${eventName}.Volunteers.Signups.byUser`, bookedUserId).ready()

    const sel = { userId: bookedUserId, status: { $in: ['confirmed', 'pending'] } }
    // TODO when moving to methods improve sort here. As mini mongo doesn't support aggregations
    // can't do it without querying for each shift
    return collections.signups.find(sel, { sort: { type: 1, start: 1 } }).fetch()
  }, [eventName, userId])

  const [projectEdit, setProjectEdit] = useState()
  return (
    <>
      <Modal
        isOpen={!!projectEdit}
        closeModal={() => setProjectEdit()}
        title={projectEdit?.project?.title}
      >
        {projectEdit && (
          <ProjectSignupForm
            project={projectEdit.project}
            signup={projectEdit.signup}
            onSubmit={setProjectEdit}
          />
        )}
      </Modal>
      <div className="container-fluid p-0 bookedTable">
        <div className="row">
          <div className="container-fluid">
            {allShifts.map(shift => (
              <div key={shift._id} className="flex-column bookedTableItem p-0">
                <SignupUserRowView signup={shift} editProject={setProjectEdit} />
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  )
}
