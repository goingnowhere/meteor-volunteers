/* global __coffeescriptShare */
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range' // eslint-disable-line

const share = __coffeescriptShare

const moment = extendMoment(Moment)
moment.tz.setDefault(share.timezone.get())

export const formatDateTime = date => moment(date).format('MMM Do, HH:mm')
export const formatDate = date => moment(date).format('MMM Do (ddd)')
export const formatTime = date => moment(date).format('HH:mm')
export const differenceTime = (start, end) => `(+${moment(end).diff(start, 'days') + 1})`
export const longformDay = date => moment(date).format('dddd')

export const isSameDay = (start, end) => moment(start).isSame(moment(end), 'day')
