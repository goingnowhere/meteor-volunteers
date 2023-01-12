import React, { useContext, useEffect, useState } from 'react'
import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'
import Blaze from 'meteor/gadicc:blaze-react-component'
import SimpleSchema from 'simpl-schema'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'
import { AutoForm } from 'meteor/aldeed:autoform'

import { t } from '../common/i18n'
import { collections } from '../../../both/collections/initCollections'
import { meteorCall } from '../../../both/utils/methodUtils'
import { reactContext } from '../../clientInit'
import { DutyBody } from './DutyBody.jsx'

const moment = extendMoment(Moment)

const makeFormSchema = (project, signup) => {
  const start = moment(project.start)
  const end = moment(project.end)
  const allDays = Array.from(moment.range(start, end).by('days'))

  let firstDay, lastDay
  if (signup?.start) {
    firstDay = moment(signup.start)
    lastDay = moment(signup.end)
  } else if (allDays.length > 0) {
    [firstDay] = allDays
    lastDay = allDays[allDays.length - 1]
  }

  return new SimpleSchema({
    start: {
      type: Date,
      label() { return t('start') },
      autoform: {
        afFieldHelpText() { return t('project_start_help') },
        group: 'Period',
        groupHelp() { return t('project_period_help') },
        afFieldInput: {
          type: 'datetimepicker',
          opts() {
          // formatDate:'DD-MM-YYYY',
          // minDate: firstDay.format('DD-MM-YYYY')
          // maxDate: lastDay.format('DD-MM-YYYY')
            return {
              value: firstDay.format('DD-MM-YYYY'),
              format: 'DD-MM-YYYY',
              timepicker: false,
            }
          },
        },
      },
    },
    end: {
      type: Date,
      label() { return t('end') },
      autoform: {
        afFieldHelpText() { return t('project_end_help') },
        group: 'Period',
        afFieldInput: {
          type: 'datetimepicker',
          opts() {
          // formatDate:'DD-MM-YYYY',
          // minDate: firstDay.format('DD-MM-YYYY')
          // maxDate: lastDay.format('DD-MM-YYYY')
            return {
              value: lastDay.format('DD-MM-YYYY'),
              format: 'DD-MM-YYYY',
              timepicker: false,
            }
          },
        },
      },
    },
    parentId: {
      type: String,
      autoform: {
        type: 'hidden',
      },
    },
    shiftId: {
      type: String,
      autoform: {
        type: 'hidden',
      },
    },
    userId: {
      type: String,
      autoform: {
        type: 'hidden',
      },
    },
    type: {
      type: String,
      autoform: {
        type: 'hidden',
      },
      defaultValue: 'project',
    },
  })
}

export const ProjectSignupForm = ({ project, signup, onSubmit }) => {
  const userId = useTracker(() => Meteor.userId())
  const Volunteers = useContext(reactContext)
  const [confirmed, setConfirmed] = useState()

  useEffect(() => {
    meteorCall(Volunteers, 'getProjectStaffing', project._id,
      (err, confirmedStaffing) => {
        if (!err) {
          setConfirmed(confirmedStaffing)
        }
      })
  }, [Volunteers, project])

  const methodNameInsert = `${collections.signups._name}.insert`
  const methodNameUpdate = `${collections.signups._name}.update`
  const [formSchema, setFormSchema] = useState(() => makeFormSchema(project, signup))

  useEffect(() => {
    setFormSchema(makeFormSchema(project, signup))
  }, [project, signup])

  useEffect(() => {
    AutoForm.addHooks([
      'projectSignupsInsert',
      'projectSignupsUpdate',
      'InsertShiftGroupFormId',
      'UpdateShiftGroupFormId',
    ], {
      onSuccess() {
        if (onSubmit) onSubmit()
      },
    })
  }, [onSubmit])

  return (
    <>
      <DutyBody description={project.description} />
      <Blaze
        template="projectStaffingChart"
        project={project}
        confirmedSignups={confirmed}
      />
      {signup?._id ? (
        <Blaze
          template="quickForm"
          schema={formSchema}
          id="projectSignupsUpdate"
          type="method-update"
          meteormethod={methodNameUpdate}
          doc={signup}
        />
      ) : (
        <Blaze
          template="quickForm"
          schema={formSchema}
          id="projectSignupsInsert"
          type="method"
          meteormethod={methodNameInsert}
          doc={
            {
              parentId: project.parentId,
              shiftId: project._id,
              userId,
              type: 'project',
            }
          }
        />
      )}
    </>
  )
}
