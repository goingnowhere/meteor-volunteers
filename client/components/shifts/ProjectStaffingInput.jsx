import React, { useCallback, useEffect, useMemo, useState } from "react"
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'
import { T } from '../common/i18n'

const moment = extendMoment(Moment)

export function ProjectStaffingInput({ start, end, staffing = [], callback }) {
  const startMoment = useMemo(() => moment(start), [start])
  const datesSet = useMemo(() => start && end && startMoment.isBefore(end), [startMoment, end])
  const [staffingArray, setStaffingArray] = useState(staffing)
  const [days, setDays] = useState([])
  useEffect(() => {
    if (start && end) {
      const days = Array.from(moment.range(start, end).by('days')).map(day => day.format('MMM Do'))
      let newStaffing
      if (days.length > staffingArray.length) {
        newStaffing = staffingArray.concat(
          Array(days.length - staffingArray.length).fill({ min: 2, max: 4 })
        )
      } else {
        newStaffing = staffingArray.slice(0, days.length)
      }
      setStaffingArray(newStaffing)
      callback(newStaffing)
      setDays(days)
    }
  }, [start, end])

  const updateStaffing = useCallback((val, index, key) => {
    const bef = staffingArray.slice(0, index)
    const toUp = staffingArray[index]
    const af = staffingArray.slice(index + 1)
    const newThing = [
      ...bef,
      { ...toUp, [key]: val },
      ...af,
    ]
    callback(newThing)
    setStaffingArray(newThing)
  }, [staffingArray, callback])
  return (
    <div>
      {datesSet && (
        <>
          <div className="row">
            <div className="col-md-4 offset-md-4">
              <T>min_people</T>
            </div>
            <div className="col-md-4">
              <T>max_people</T>
            </div>
          </div>
          {staffingArray.map((staffingValue, index) => (
            <div key={index} className="row">
              <div className="col-md-4">
                {days[index]}
              </div>
              <div className="col-md-4">
                <input
                  className="form-control"
                  type="number"
                  onChange={e => updateStaffing(Number(e.target.value), index, 'min')}
                  value={staffingValue.min || 2}
                />
              </div>
              <div className="col-md-4">
                <input
                  className="form-control"
                  type="number"
                  onChange={e => updateStaffing(Number(e.target.value), index, 'max')}
                  value={staffingValue.max || 4}
                />
              </div>
            </div>
          ))}
        </>
      )}
    </div>
  )
}
