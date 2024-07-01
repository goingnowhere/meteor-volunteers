import { Meteor } from 'meteor/meteor'

import { dutyPriorityScore, userPrefsMatch } from '../collections/utils'

export const signupDetailPipeline = (collections, included) => [
  ...!included.includes('dept') ? [] : [
    {
      $lookup: {
        from: collections.department._name,
        localField: 'parentId',
        foreignField: '_id',
        as: 'dept',
      },
    }, {
      $unwind: {
        path: '$dept',
        preserveNullAndEmptyArrays: true,
      },
    },
  ],
  ...!included.includes('team') ? [] : [
    {
      $lookup: {
        from: collections.team._name,
        localField: 'parentId',
        foreignField: '_id',
        as: 'team',
      },
    }, {
      $unwind: {
        path: '$team',
        preserveNullAndEmptyArrays: true,
      },
    },
  ],
  ...!included.includes('duty') ? [] : [
    {
      $lookup: {
        from: collections.lead._name,
        localField: 'shiftId',
        foreignField: '_id',
        as: 'lead',
      },
    }, {
      $lookup: {
        from: collections.shift._name,
        localField: 'shiftId',
        foreignField: '_id',
        as: 'shift',
      },
    }, {
      $lookup: {
        from: collections.project._name,
        localField: 'shiftId',
        foreignField: '_id',
        as: 'project',
      },
    }, {
      $addFields: {
        duty: {
          $switch: {
            branches: [
              {
                case: { $gt: [{ $size: '$shift' }, 0] },
                then: { $arrayElemAt: ['$shift', 0] },
              }, {
                case: { $gt: [{ $size: '$lead' }, 0] },
                then: { $arrayElemAt: ['$lead', 0] },
              }, {
                case: { $gt: [{ $size: '$project' }, 0] },
                then: { $arrayElemAt: ['$project', 0] },
              },
            ],
          },
        },
      },
    },
  ],
  ...!included.includes('user') ? [] : [{
    $lookup: {
      from: Meteor.users._name,
      let: { userId: '$userId' },
      pipeline: [
        {
          $match: { $expr: { $eq: ['$_id', '$$userId'] } },
        }, {
          // Only return public user fields
          $project: {
            emails: true,
            profile: true,
            ticketId: true,
          },
        },
      ],
      as: 'user',
    },
  }, {
    $unwind: { path: '$user' },
  },
  ],
  { $sort: { createdAt: 1 } },
]

export const projectsAndStaffingAggregation = (collections, type, eventStart, eventEnd) => [
  {
    $lookup: {
      from: collections.project._name,
      let: { teamId: '$_id' },
      pipeline: [
        {
          $match: { $expr: { $eq: ['$parentId', '$$teamId'] } },
        }, {
          $match: {
            // Only used in aggregated form, so include everything
            // policy: { $in: ['public', 'requireApproval'] },
            ...type === 'build' && eventStart && { start: { $lt: eventStart } },
            ...type === 'strike' && eventEnd && { end: { $gt: eventEnd } },
          },
        },
        {
          $lookup: {
            from: collections.signups._name,
            let: { shiftId: '$_id' },
            pipeline: [
              { $match: { $expr: { $eq: ['$$shiftId', '$shiftId'] }, status: 'confirmed' } },
              {
                $addFields: { test: '$$shiftId' },
              },
              {
                // Remove anything about user so this can be public
                $unset: ['userId'],
              },
            ],
            as: 'signups',
          },
        },
      ],
      as: 'projects',
    },
  },
]

export const projectPriorityAggregation = ({
  collections,
  match,
  skillsPath,
  quirksPath,
}) => [
  {
    $match: {
      policy: { $in: ['public', 'requireApproval'] },
      ...match,
    },
  },
  // Get team for skills and quirk info
  {
    $lookup: {
      from: collections.team._name,
      localField: 'parentId',
      foreignField: '_id',
      as: 'team',
    },
  },
  {
    $unwind: { path: '$team' },
  },
  // Get confirmed signups to judge staffing levels
  {
    $lookup: {
      from: collections.signups._name,
      let: { shiftId: '$_id' },
      pipeline: [
        { $match: { $expr: { $eq: ['$$shiftId', '$shiftId'] }, status: 'confirmed' } },
        {
          $project: {
            days: {
              // If moving to later than mongo 5.0 can use dateDiff
              $add: [{ $divide: [{ $subtract: ['$end', '$start'] }, 1000 * 60 * 60 * 24] }, 1],
            },
          },
        },
      ],
      as: 'signups',
    },
  },
  {
    $addFields: {
      // A literal to indicate what type of 'duty'
      type: 'project',
      volDays: { $sum: '$signups.days' },
      minStaffing: { $sum: '$staffing.min' },
      maxStaffing: { $sum: '$staffing.max' },
      quirks: '$team.quirks',
      skills: '$team.skills',
    },
  },
  {
    $addFields: {
      // How many skills or quirks match the user's
      preferenceScore: skillsPath && quirksPath ? userPrefsMatch(skillsPath, quirksPath) : 1,
      priorityScore: dutyPriorityScore,
      minRemaining: { $max: [0, { $subtract: ['$minStaffing', '$volDays'] }] },
      maxRemaining: { $max: [0, { $subtract: ['$maxStaffing', '$volDays'] }] },
    },
  },
  {
    $addFields: {
      score: {
        $add: [
          { $multiply: ['$maxRemaining', { $add: [1, '$preferenceScore'] }] },
          { $multiply: ['$minRemaining', '$priorityScore', { $add: [1, '$preferenceScore'] }] },
        ],
      },
    },
  },
  { $sort: { score: -1 } },
]

export const rotaPriorityAggregation = ({
  collections,
  match,
  shiftMatch = {},
  skillsPath,
  quirksPath,
}) => [
  {
    $match: {
      policy: { $in: ['public', 'requireApproval'] },
      ...match,
    },
  },
  // Get team for skills and quirk info
  {
    $lookup: {
      from: collections.team._name,
      localField: 'parentId',
      foreignField: '_id',
      as: 'team',
    },
  },
  {
    $unwind: { path: '$team' },
  },
  // Get the actual shifts
  {
    $lookup: {
      from: collections.shift._name,
      let: { rotaId: '$_id' },
      as: 'shiftObjects',
      pipeline: [
        {
          $match: {
            $expr: { $eq: ['$$rotaId', '$rotaId'] },
            ...shiftMatch,
          },
        },
        // Get confirmed and pending signups to judge staffing levels
        { $sort: { start: 1 } },
        {
          $lookup: {
            from: collections.signups._name,
            let: { shiftId: '$_id' },
            as: 'signups',
            pipeline: [
              { $match: { $expr: { $and: [{ $eq: ['$$shiftId', '$shiftId'] }, { $in: ['$status', ['confirmed', 'pending']] }] } } },
              {
                $group: {
                  _id: null,
                  confirmed: {
                    $sum: { $cond: { if: { $eq: ['$status', 'confirmed'] }, then: 1, else: 0 } },
                  },
                  pending: {
                    $sum: { $cond: { if: { $eq: ['$status', 'pending'] }, then: 1, else: 0 } },
                  },
                  userStatuses: { $addToSet: { _id: '$_id', userId: '$userId', status: '$status' } },
                },
              },
            ],
          },
        },
        { $unwind: { path: '$signups', preserveNullAndEmptyArrays: true } },
        {
          $addFields: {
            maxRemaining: { $max: [0, { $subtract: ['$max', { $ifNull: ['$signups.confirmed', 0] }] }] },
            minRemaining: { $max: [0, { $subtract: ['$min', { $ifNull: ['$signups.confirmed', 0] }] }] },
          },
        },
        {
          $addFields: {
            maxNotPending: { $max: [0, { $subtract: ['$maxRemaining', { $ifNull: ['$signups.pending', 0] }] }] },
            minNotPending: { $max: [0, { $subtract: ['$minRemaining', { $ifNull: ['$signups.pending', 0] }] }] },
          },
        },
      ],
    },
  },
  { $match: { $expr: { $gt: [{ $size: '$shiftObjects' }, 0] } } },
  {
    $addFields: {
      // A literal to indicate what type of 'duty'
      type: 'rota',
      firstShift: { $arrayElemAt: ['$shiftObjects', 0] },
      quirks: '$team.quirks',
      skills: '$team.skills',
    },
  },
  {
    $addFields: {
      // Min 1 hour as people do weird things...
      shiftHours: {
        $max: [1, {
          $divide: [{ $subtract: ['$firstShift.end', '$firstShift.start'] }, 1000 * 60 * 60],
        }],
      },
      minRemaining: { $sum: '$shiftObjects.minRemaining' },
      maxRemaining: { $sum: '$shiftObjects.maxRemaining' },
      minNotPending: { $sum: '$shiftObjects.minNotPending' },
      maxNotPending: { $sum: '$shiftObjects.maxNotPending' },
    },
  },
  {
    $addFields: {
      // How many skills or quirks match the user's
      preferenceScore: skillsPath && quirksPath ? userPrefsMatch(skillsPath, quirksPath) : 1,
      priorityScore: dutyPriorityScore,
    },
  },
  {
    $addFields: {
      score: {
        $add: [
          { $multiply: ['$maxRemaining', '$shiftHours', { $add: [1, '$preferenceScore'] }] },
          { $multiply: ['$minRemaining', '$priorityScore', '$shiftHours', { $add: [1, '$preferenceScore'] }] },
        ],
      },
    },
  },
  { $sort: { score: -1 } },
]
