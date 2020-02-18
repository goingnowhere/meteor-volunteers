import { ReactiveAggregate } from 'meteor/jcbernack:reactive-aggregate'
import { initPublications } from './publications'
import { auth } from '../both/utils/auth'

share.initPublications = (eventName) ->

  unitPublicPolicy = { policy: { $in: ["public"] } }

  Meteor.publish "#{eventName}.Volunteers.volunteerForm.list", (userIds = []) ->
    if auth.isManager() # publish manager only information
      share.VolunteerForm.find({userId: {$in: userIds}})
    else if auth.isLead()
      # TODO: the fields of the should have a field 'confidential that allow
      # here to filter which information to publish to all leads
      share.VolunteerForm.find({userId: {$in: userIds}})
    else
      return null

  Meteor.publish "#{eventName}.Volunteers.volunteerForm", (userId = this.userId) ->
    if auth.isLead()
      share.VolunteerForm.find({userId: userId})
    else
      if !userId? or this?.userId == userId
        share.VolunteerForm.find({userId: this.userId},{fields: {private_notes: 0}})
      else
        return null

  # this pipeline sort add the totalscore field to a team
  teamPipeline = [
    # get all the shifts associated to this team
    { $lookup: {
      from: share.TeamShifts._name,
      localField: "_id",
      foreignField: "parentId",
      as: "duties"
    }},
    { $unwind: "$duties" },
    # project the results in mongo 3.4 use addfields instead
    { $project: {
      name: 1,
      description: 1,
      parentId: 1,
      quirks: 1,
      skills: 1,
      duties: 1,
      p : {
        $cond: [{ $eq: [ "$duties.priority", "normal"]},1,
          { $cond: [{ $eq: [ "$duties.priority", "important"]},3,
            {
              $cond: [{ $eq: [ "$duties.priority", "essential"]},5,0]
            }
          ]}
        ]
      }}
    },
    { $group: {
      _id: "$_id",
      # types: { $addToSet: "$duties.priority" },
      totalscore: { $sum: "$p"}, # assign a score to each team based on its shifts' priority
      name: {$first: "$name"},
      description : {$first: "$description"},
      parentId: {$first: "$parentId"}
      quirks: {$first: "$quirks"},
      skills: {$first: "$skills"},
    }},
  ]

  # Reactive publication sorted by user preferences
  # I use the pipeline above + adding one more field for the userPref
  Meteor.publish "#{eventName}.Volunteers.team.ByUserPref", (quirks,skills) ->
    if this.userId
      ReactiveAggregate(this, share.Team, teamPipeline.concat([
        { $project: {
          name: 1,
          description: 1,
          parentId: 1,
          totalscore: 1
          quirks:  { $ifNull: [ "$quirks", [] ] },
          skills:  { $ifNull: [ "$skills", [] ] },
          intq: {"$setIntersection": [ quirks, "$quirks" ] },
          ints: {"$setIntersection": [ skills, "$skills" ] },
        }},
        {$project: {
          name: 1,
          description: 1,
          parentId: 1,
          quirks: 1,
          skills: 1,
          totalscore: 1
          subq: { $size: { $ifNull: [ "$intq", [] ] } },
          subs: { $size: { $ifNull: [ "$ints", [] ] } },
        }},
        {$project: {
          name: 1,
          description: 1,
          parentId: 1,
          quirks: 1,
          skills: 1,
          totalscore: 1
          # assign a score to the team w.r.t. the user preferences
          userpref: { $sum: [ "$subq", "$subs" ]}
        }},
        # remove all teams without duties
        { $match: { totalscore: { $gt: 0 } }},
        { $sort: { totalscore: -1 } }
      ]))

  Meteor.publish "#{eventName}.Volunteers.team", (sel={}) ->
    unless auth.isManager()
      sel = _.extend(sel,unitPublicPolicy)
    ReactiveAggregate(this, share.Team,
      [ { $match: sel } ].concat(
        teamPipeline.concat( [
          { $match: { totalscore: { $gt: 0 } }},
          { $sort: { totalscore: -1 } }
          ]
        )
      )
    )
  ######################################
  # Below here, all public information #
  ######################################

  # not reactive
  Meteor.publish "#{eventName}.Volunteers.organization", () ->
    sel = {}
    unless (not this.userId) || auth.isManager()
      sel = unitPublicPolicy
    dp = share.Department.find(sel)
    t = share.Team.find(sel)
    dv = share.Division.find(sel)
    return [dv,dp,t]

  Meteor.publish "#{eventName}.Volunteers.division", (sel={}) ->
    if this.userId && auth.isLead()
      share.Division.find(sel)
    else
      share.Division.find(_.extend(sel,unitPublicPolicy))

  Meteor.publish "#{eventName}.Volunteers.department", (sel={}) ->
    if this.userId && auth.isLead()
      share.Department.find(sel)
    else
      share.Department.find(_.extend(sel,unitPublicPolicy))

  # these two publications are used in the teamEdit and departmentEdit forms
  Meteor.publish "#{eventName}.Volunteers.team.backend", (parentId = '') ->
    if this.userId && auth.isLead(this.userId,[parentId])
      share.Team.find({parentId})
    else
      share.Team.find(_.extend({parentId},unitPublicPolicy))

  Meteor.publish "#{eventName}.Volunteers.department.backend", (parentId = '') ->
    if this.userId && auth.isLead(this.userId,[parentId])
      share.Department.find({parentId})
    else
      share.Department.find(_.extend({parentId},unitPublicPolicy))

  # migrate to JS:
  initPublications(eventName)
