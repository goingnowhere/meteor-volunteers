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
]
