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

const processData = (staffing) => {
  const wanted = staffing.wanted.map((want, i) => Math.max(0, want - staffing.needed[i]))
  return {
    labels: staffing.days.map((t) => moment(t).format('MMM Do')),
    datasets: [
      { label: 'confirmed', data: staffing.confirmed, backgroundColor: '#D6E9C6' },
      { label: 'needed', data: staffing.needed, backgroundColor: '#CD5C5C' },
      { label: 'wanted', data: wanted, backgroundColor: '#ffe94D' },
    ],
  }
}

export const ProjectStaffingDisplay = ({ staffing }) => {
  const barData = useMemo(() => processData(staffing), [staffing])
  return (
    <div className="chart-container">
      <Bar data={barData} options={chartOptions} />
    </div>
  )
}
