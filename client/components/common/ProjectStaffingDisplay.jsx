import React, { useMemo } from 'react'
// eslint-disable-next-line import/no-unresolved
import { Bar } from 'react-chartjs-2'
import moment from 'moment-timezone'

const chartOptions = {
  scales: {
    xAxes: [{
      stacked: true,
    }],
    yAxes: [{
      stacked: true,
    }],
  },
}

const processData = (staffing, signup) => {
  // Maybe we could do this in the method to avoid having this logic split
  let signedUp = []
  if (signup) {
    const signupStart = moment(signup.start)
    const signupEnd = moment(signup.end)
    signedUp = staffing.days.map(day =>
      (moment(day).isBetween(signupStart, signupEnd, 'days', '[]') ? 1 : 0))
  }
  const confirmed = staffing.confirmed.map((num, i) => num - (signedUp[i] ?? 0))
  // FIXME i18n!
  return {
    labels: staffing.days.map((t) => moment(t).format('MMM Do')),
    datasets: [
      ...!signup ? [] : [{
        label: signup.status,
        data: signedUp,
        backgroundColor: '#3944E8',
      }],
      { label: 'filled', data: confirmed, backgroundColor: '#D6E9C6' },
      { label: 'needed', data: staffing.needed, backgroundColor: '#CD5C5C' },
      { label: 'wanted', data: staffing.wanted, backgroundColor: '#ffe94D' },
    ],
  }
}

export const ProjectStaffingDisplay = ({ staffing, signup }) => {
  const barData = useMemo(() => processData(staffing, signup), [staffing, signup])
  return (
    <div className="chart-container">
      <Bar data={barData} options={chartOptions} />
    </div>
  )
}
