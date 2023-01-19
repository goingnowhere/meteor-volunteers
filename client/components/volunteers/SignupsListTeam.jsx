import { Meteor } from 'meteor/meteor'
import { Mongo } from 'meteor/mongo'
import { useTracker } from 'meteor/react-meteor-data'
import React, { useContext, useState } from 'react'

import { reactContext } from '../../clientInit'
import { SignupsListItem } from '../shifts/SignupsListItem.jsx'
import { Modal } from '../common/Modal.jsx'
import { ShiftSignupModalContents } from '../shifts/ShiftSignupModalContents.jsx'
import { ProjectSignupForm } from '../shifts/ProjectSignupForm.jsx'

const ShiftTitles = new Mongo.Collection(null)

// coll contains shifts unique shifts title
const addLocalDutiesCollection = (team, duties, type, filter, limit) => {
  ShiftTitles.remove({ type, parentId: filter.parentId })
  const shifts = duties.find(filter, { limit }).fetch()
  _.chain(shifts).groupBy('title').forEach(([shift], title) => {
    const duty = {
      _id: shift._id,
      type,
      title,
      description: shift.description,
      priority: shift.priority,
      parentId: filter.parentId,
      policy: filter.policy,
      team,
    }
    if (type === 'project') {
      duty.start = shift.start
      duty.end = shift.end
      duty.staffing = shift.staffing
    }
    ShiftTitles.insert(duty)
  }).value()
}

export function SignupsListTeam({ team, dutyType = '', filters }) {
  const Volunteers = useContext(reactContext)
  const { collections, eventName } = Volunteers

  const [signupDuty, setSignupDuty] = useState(null)

  const { allShifts } = useTracker(() => {
    const sel = { parentId: team._id }
    // TODO Only need one to get details of the shift but this limits to only one project
    // per team. We should add a 'projectGroups' aggregation in the same way as 'shiftGroups'
    const limit = 10
    if (filters?.priorities) {
      sel.priority = { $in: filters.priorities }
    }
    const subs = []
    switch (dutyType) {
    case 'shift':
      subs.push(Meteor.subscribe(`${eventName}.Volunteers.shiftGroups`, sel))
      break
    case 'task':
      subs.push(Meteor.subscribe(`${eventName}.Volunteers.duties`, dutyType, sel, limit))
      if (subs.every(sub => sub.ready())) {
        addLocalDutiesCollection(team, collections.task, dutyType, sel, limit)
      }
      break
    case 'project':
      subs.push(Meteor.subscribe(`${eventName}.Volunteers.duties`, dutyType, sel, limit))
      if (subs.every(sub => sub.ready())) {
        addLocalDutiesCollection(team, collections.project, dutyType, sel, limit)
      }
      break
    default:
      subs.push(Meteor.subscribe(`${eventName}.Volunteers.shiftGroups`, sel))
      subs.push(Meteor.subscribe(`${eventName}.Volunteers.duties`, 'task', sel, limit))
      subs.push(Meteor.subscribe(`${eventName}.Volunteers.duties`, 'project', sel, limit))
      if (subs.every(sub => sub.ready())) {
        addLocalDutiesCollection(team, collections.task, 'task', sel, limit)
        addLocalDutiesCollection(team, collections.project, 'project', sel, limit)
      }
    }
    let allTheShifts = []
    if (subs.every(sub => sub.ready())) {
      let shiftGroups = []
      if (['lead', 'project'].includes(dutyType)) {
        sel.type = dutyType
      } else {
        shiftGroups = collections.shiftGroups.find(sel).map(
          (group) => _.extend(group, { type: 'shift', team }),
        )
      }
      const otherDuties = ShiftTitles.find(sel).fetch()
      allTheShifts = shiftGroups.concat(otherDuties)
    }
    return { allShifts: allTheShifts }
  }, [team, dutyType, filters])

  return (
    <>
      <Modal isOpen={!!signupDuty} closeModal={() => setSignupDuty(null)} title={signupDuty?.title}>
        {signupDuty?.type === 'project'
          ? <ProjectSignupForm project={signupDuty} onSubmit={setSignupDuty} />
          : <ShiftSignupModalContents duty={signupDuty} />}
      </Modal>
      {allShifts.map(duty => (
        <div key={duty._id} className="px-2 pb-0 signupsListItem">
          <SignupsListItem duty={duty} showSignupModal={setSignupDuty} />
        </div>
      ))}
    </>
  )
}
