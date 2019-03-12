/* global __coffeescriptShare */
import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import { withTracker } from 'meteor/react-meteor-data'
import React from 'react'
import ReactModal from 'react-modal'

import { findOrgUnit } from '../../../both/collections/unit'
import { DutiesListItemDate } from './DutiesListItemDate.jsx'

export const SignupModalComponent = ({
  duty,
  modalOpen,
  showModal,
  allDates,
}) => (
  <ReactModal
    isOpen={modalOpen}
    className="modal-dialog modal-lg"
    // We need to force Bootstrap to behave
    style={{ overlay: { zIndex: 1030, backgroundColor: '#0008' } }}
    onRequestClose={() => showModal(false)}
  >
    <div className="modal-content">
      <div className="modal-header">
        {duty.title}
        <button type="button" className="close" onClick={() => showModal(false)}>
          <span aria-hidden="true">&times;</span> <span className="sr-only">Close</span>
        </button>
      </div>
      <div className="modal-body">
        {allDates.map(date => (
          <div key={date._id} className="list-item row align-items-center px-2">
            <DutiesListItemDate {...date} />
          </div>
        ))}
      </div>
    </div>
  </ReactModal>
)

// TODO We should replace all of this with a method

const share = __coffeescriptShare

// client side collection
const DatesLocal = new Mongo.Collection(null)

// DatesLocal contains all shifts (dates) related to a particular title and parentId
const addLocalDatesCollection = (duties, type, filter) => {
  duties.find(filter).forEach((duty) => {
    const orgUnit = findOrgUnit(duty.parentId)
    DatesLocal.upsert(duty._id, {
      type,
      team: orgUnit && orgUnit.unit,
      signup: share.signupCollections[type].findOne({
        userId: Meteor.userId(),
        shiftId: duty._id,
      }),
      ...duty,
    })
  })
}

const dutySubNames = {
  shift: 'TeamShifts',
  task: 'TeamTasks',
  project: 'Projects',
}
const signupSubNames = {
  shift: 'ShiftSignups',
  task: 'TaskSignups',
  project: 'ProjectSignups',
}

export const SignupModal = withTracker(({ modalOpen, duty, ...props }) => {
  const { type, title, parentId } = duty
  ReactModal.setAppElement('#react-root')
  if (modalOpen) {
    const userId = Meteor.userId()
    const subs = [
      Meteor.subscribe(`${share.eventName}.Volunteers.${dutySubNames[type]}`, { title, parentId }),
      Meteor.subscribe(`${share.eventName}.Volunteers.${signupSubNames[type]}.byUser`, userId),
    ]
    if (subs.every(sub => sub.ready())) {
      addLocalDatesCollection(share.dutiesCollections[type], type, { title, parentId })
    }
  }
  return {
    modalOpen,
    duty,
    ...props,
    allDates: DatesLocal.find({ title }, { sort: { start: 1 } }).fetch(),
  }
})(SignupModalComponent)
