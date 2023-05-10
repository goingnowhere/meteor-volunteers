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
  let { confirmed, needed, wanted } = staffing
  if (signup) {
    const signupStart = moment(signup.start)
    const signupEnd = moment(signup.end)
    signedUp = staffing.days.map(day =>
      (moment(day).isBetween(signupStart, signupEnd, 'days', '[]') ? 1 : 0))
    if (signup.status === 'confirmed') {
      confirmed = staffing.confirmed.map((num, i) => num - (signedUp[i] ?? 0))
    } else if (signup.status === 'pending') {
      const newNeeded = []
      const newWanted = []
      signedUp.forEach((num, i) => {
        newWanted[i] = wanted[i]
        if (!signedUp[i]) {
          newNeeded[i] = needed[i]
        } else {
          newNeeded[i] = needed[i] - signedUp[i]
          if (newNeeded[i] < 0) {
            newWanted[i] = wanted[i] + newNeeded[i] // + because newConfirmed is negative
            newNeeded[i] = 0
          }
        }
      })
      needed = newNeeded
      wanted = newWanted
    }
  }
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
      { label: 'needed', data: needed, backgroundColor: '#CD5C5C' },
      { label: 'wanted', data: wanted, backgroundColor: '#ffe94D' },
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
