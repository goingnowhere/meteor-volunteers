import { Meteor } from 'meteor/meteor'
import { useTracker } from 'meteor/react-meteor-data'
import React, { useContext } from 'react'
import { Link, useParams } from 'react-router-dom'

import { SignupsList } from '../shifts/SignupsList.jsx'
import { reactContext } from '../../clientInit'
import { T, t } from '../common/i18n'

export const PublicDeptView = () => {
  const Volunteers = useContext(reactContext)
  const { deptId } = useParams()
  const { dept, teams, ready } = useTracker(() => {
    const deptSub = Meteor.subscribe(`${Volunteers.eventName}.Volunteers.department`, { _id: deptId })

    let foundDept = {}
    let foundTeams = []
    if (deptSub.ready()) {
      foundDept = Volunteers.collections.department.findOne(deptId)
      foundTeams = Volunteers.collections.team.find({ parentId: deptId }).fetch()
    }

    return { dept: foundDept, teams: foundTeams, ready: deptSub.ready() && '_id' in foundDept }
  }, [deptId])
  const filters = { teams: [dept._id, ...teams.map((team) => team._id)] }

  return (
    <div className="container">
      <div className="row">
        <div className="card">
          <div className="card-header">
            <h5>{dept.name}</h5>
            {dept.email && (
              <h5 className="text-muted text-right"><T>contact</T>: {dept.email}</h5>
            )}
            <div>
              <button
                type="button"
                className="nav-link dropdown-toggle btn btn-light"
                title={t('public_link')}
                data-toggle="dropdown"
              >
                <T>teams</T>
              </button>
              <div className="dropdown-menu" aria-labelledby="navbarDropdown3">
                {teams.map(team => (
                  <Link
                    key={team._id}
                    to={`/department/${deptId}/team/${team._id}`}
                    className="dropdown-item"
                  >
                    {team.name}
                  </Link>
                ))}
              </div>
            </div>
          </div>
          <p className="m-2">{dept.description}</p>
        </div>
      </div>
      <h3 className="pt-2"><T>teams_in_this_department</T></h3>
      {ready && (
        <SignupsList filters={filters} />
      )}
    </div>
  )
}
