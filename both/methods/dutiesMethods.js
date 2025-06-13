import { Meteor } from 'meteor/meteor'
import { check, Match } from 'meteor/check'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import Moment from 'moment-timezone'
import { extendMoment } from 'moment-range'

import {
  projectsAndStaffingAggregation,
  projectPriorityAggregation,
  rotaPriorityAggregation,
} from './aggregations'

const moment = extendMoment(Moment)

export function initDutiesMethods(volunteersClass) {
  const { collections, services: { auth, stats }, settings: settingsVar } = volunteersClass
  const settings = settingsVar.get()

  function createMethod(collection) {
    const collectionName = collection._name
    Meteor.methods({
      [`${collectionName}.remove`](id) {
        console.log(`${collectionName}.remove`, id)
        check(id, String)
        const doc = collection.findOne(id)
        if (!auth.isLead(Meteor.userId(), doc.parentId)) {
          throw new Meteor.Error(403, 'Insufficient Permission')
        }
        collection.remove(id)
        collections.signups.update({ shiftId: id }, { $set: { status: 'cancelled' } })
      },
      [`${collectionName}.insert`](doc) {
        console.log([`${collectionName}.insert`, doc])
        check(doc, Object)
        collection.simpleSchema().validate(doc)
        if (!auth.isLead(Meteor.userId(), doc.parentId)) {
          throw new Meteor.Error(403, 'Insufficient Permission')
        }
        return collection.insert(doc)
      },
      [`${collectionName}.update`](doc) {
        console.log([`${collectionName}.update`, doc._id, doc.modifier])
        check(doc, Object)
        collection.simpleSchema().validate(doc.modifier, { modifier: true })
        const olddoc = collection.findOne(doc._id)
        if (!this.isSimulation && !auth.isLead(Meteor.userId(), olddoc.parentId)) {
          throw new Meteor.Error(403, 'Insufficient Permission')
        }
        return collection.update(doc._id, doc.modifier)
      },
    })
  }

  // Actually create the methods (nothing to return as they're not 'ValidatedMethod's)
  Object.values(collections.dutiesCollections).forEach(dutyColl => {
    createMethod(dutyColl)
  })

  return {
    listOpenShifts: new ValidatedMethod({
      name: 'shifts.open.list',
      validate({ dates }) {
        check(dates?.start, Date)
        check(dates?.end, Date)
      },
      run({
        teams,
        dates,
      }) {
        // Aggregate is only available on the server
        if (!Meteor.isServer) {
          return []
        }
        const match = {
          start: { $lt: dates.end },
          end: { $gt: dates.start },
          ...teams && { parentId: { $in: teams } },
        }
        const projects = collections.project.aggregate([
          ...projectPriorityAggregation({
            collections,
            match,
          }),
        ])
        const rotas = collections.rotas.aggregate([
          ...rotaPriorityAggregation({
            collections,
            match,
            shiftMatch: match,
          }),
        ])

        return [...projects, ...rotas]
          .sort((a, b) => b.score - a.score)
      },
    }),

    listOpenShiftsByPref: new ValidatedMethod({
      name: 'shifts.byPref.list',
      validate: ({ type }) => check(type, Match.OneOf('all', 'build', 'strike', 'event', 'dates')),
      run({
        type,
        teams,
        dates,
      }) {
        // Aggregate is only available on the server
        if (!Meteor.isServer) {
          return []
        }
        const now = new Date()
        const eventStart = settings.eventPeriod?.start
        // TODO Ideally eventPeriod.end should be the actual end and the date display for the
        // selector should be hacked, instead of having to do a +1 day everywhere...
        const eventEndMoment = settings.eventPeriod && moment(settings.eventPeriod.end).add(1, 'day')
        const eventEnd = eventEndMoment?.toDate()
        const endOrNow = eventEnd && moment(now).isBefore(eventEndMoment) ? eventEnd : now
        const startOrNow = eventStart && moment(now).isBefore(eventStart) ? eventStart : now
        const match = {
          ...type === 'build' && eventStart && { start: { $lt: eventStart }, end: { $gt: now } },
          ...type === 'strike' && endOrNow && { end: { $gt: endOrNow } },
          ...type === 'event' && startOrNow && eventEnd && { end: { $gt: startOrNow }, start: { $lt: eventEnd } },
          ...type === 'all' && { end: { $gt: now } },
          ...type === 'dates' && dates && { start: { $lt: dates.end }, end: { $gt: dates.start } },
          ...teams && { parentId: { $in: teams } },
        }
        const results = collections.volunteerForm.aggregate([
          { $match: { userId: this.userId } },
          { $project: { skills: true, quirks: true } },
          {
            $lookup: {
              from: collections.project._name,
              let: { skills: '$skills', quirks: '$quirks' },
              as: 'projects',
              pipeline: [
                ...projectPriorityAggregation({
                  collections,
                  skillsPath: '$$skills',
                  quirksPath: '$$quirks',
                  match,
                }),
              ],
            },
          },
          {
            $lookup: {
              from: collections.rotas._name,
              let: { skills: '$skills', quirks: '$quirks', userId: '$userId' },
              as: 'rotas',
              pipeline: [
                ...rotaPriorityAggregation({
                  collections,
                  skillsPath: '$$skills',
                  quirksPath: '$$quirks',
                  match,
                  shiftMatch: match,
                }),
              ],
            },
          },
        ])

        return (results[0] && [...results[0].projects, ...results[0].rotas]
          .sort((a, b) => b.score - a.score)) ?? []
      },
    }),

    getProjectSignupStats: new ValidatedMethod({
      name: 'project.staffing.report',
      validate: ({ type, deptId, teamId }) => {
        check(type, Match.OneOf('build', 'strike', 'build-strike'))
        check(deptId, Match.Maybe(String))
        check(teamId, Match.Maybe(String))
        if (deptId && teamId) {
          throw new Match.Error(400, 'Can\'t specify both team and dept')
        }
      },
      run({
        type,
        deptId,
        teamId,
      }) {
        // Aggregate is only available on the server
        if (!Meteor.isServer) {
          return []
        }
        if (!settings.buildPeriod || !settings.eventPeriod || !settings.strikePeriod) {
          throw new Meteor.Error(500, 'Invalid event settings')
        }
        const buildStart = moment(settings.buildPeriod.start)
        const eventStart = moment(settings.eventPeriod.start)
        const eventEnd = moment(settings.eventPeriod.end)
        const strikeEnd = moment(settings.strikePeriod.end)
        const days = [
          ...type.includes('build') ? moment.range(buildStart, eventStart).by('days') : [],
          ...type.includes('strike') ? moment.range(eventEnd, strikeEnd).by('days') : [],
        ]

        const projectData = collections.team.aggregate([
          {
            $match: {
              policy: 'public',
              ...((!teamId && !deptId)
                && teamId ? { _id: teamId } : { parentId: deptId }
              ),
            },
          },
          ...projectsAndStaffingAggregation(
            collections, type, eventStart.toDate(), eventEnd.toDate(),
          ),
        ])

        const projStats = projectData.map((team) => {
          const allProjectStats = team.projects.map((proj) =>
            stats.projectSignupsConfirmed(proj, proj.signups, days))
          const staffingStats = allProjectStats.length < 1
            ? {}
            : allProjectStats.reduce((combined, curr) => ({
              confirmed: combined.confirmed.map((count, i) => count + curr.confirmed[i]),
              needed: combined.needed.map((count, i) => count + curr.needed[i]),
              wanted: combined.wanted.map((count, i) => count + curr.wanted[i]),
            }))
          return {
            team: team.name,
            stats: staffingStats,
          }
        })

        return {
          days: days.map(day => day.toDate()),
          allTeams: projStats,
        }
      },
    }),
  }
}
