import { Meteor } from 'meteor/meteor'

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
