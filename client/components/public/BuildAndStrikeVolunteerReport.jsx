import React, { useContext } from 'react'
import moment from 'moment-timezone'
// eslint-disable-next-line import/no-unresolved
import { Bar } from 'react-chartjs-2'

import { reactContext } from '../../clientInit'
import { useMethodCallData } from '../../utils/useMethodCallData'
import { Loading } from '../common/Loading.jsx'

const chartOptions = {
  maintainAspectRatio: false,
  scales: {
    xAxes: [{
      stacked: true,
    }],
    yAxes: [{
      stacked: true,
    }],
  },
}

export function BuildAndStrikeVolunteerReport({
  className,
  type,
  deptId,
  teamId,
}) {
  const { methods } = useContext(reactContext)
  const [{ days, allTeams }, isLoaded] = useMethodCallData(
    methods.getProjectSignupStats, { type, deptId, teamId },
  )

  const confirmed = isLoaded && days.map((_day, i) =>
    allTeams.reduce((sum, { stats }) => sum + (stats.confirmed?.[i] ?? 0), 0))
  const needed = isLoaded && days.map((_day, i) =>
    allTeams.reduce((sum, { stats }) => sum + (stats.needed?.[i] ?? 0), 0))
  const wanted = isLoaded && days.map((_day, i) =>
    allTeams.reduce((sum, { stats }) => sum + (stats.wanted?.[i] ?? 0), 0))
  const data = isLoaded && {
    labels: days.map((t) => moment(t).format('MMM Do')),
    datasets: [
      { label: 'filled', data: confirmed, backgroundColor: '#D6E9C6' },
      { label: 'needed', data: needed, backgroundColor: '#CD5C5C' },
      { label: 'wanted', data: wanted, backgroundColor: '#FFE94D' },
    ],
  }

  return (
    <div className={`chart-container ${className ?? ''}`}>
      {!isLoaded ? (
        <Loading />
      ) : (
        <Bar data={data} options={chartOptions} height={250} />
      )}
    </div>
  )
}
