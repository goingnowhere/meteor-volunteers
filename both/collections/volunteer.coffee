import SimpleSchema from 'simpl-schema'

# this is the base Volunteers form schema
share.Schemas.VolunteerForm = new SimpleSchema(
  userId:
    type: String
    optional: true
    autoValue: () -> this.userId
    autoform:
      omit: true
  createdAt:
    type: Date
    optional: true
    autoValue: () ->
      if this.isInsert then return new Date
      else this.unset()
    autoform:
      omit: true
  private_notes:
    type: String
    label: () -> TAPi18n.__("notes")
    optional: true
    max: 1000
    autoform:
      rows:4
)

commonSignups = new SimpleSchema(
  parentId: String
  shiftId: String
  userId: String
  createdAt:
    type: Date
    optional: true
    autoValue: () ->
      if this.isInsert then return new Date
      else this.unset()
    autoform:
      omit: true
  status:
    type: String
    allowedValues: ["confirmed", "pending", "refused", "bailed"]
    autoform:
      omit: true
      defaultValue: "pending"
)
share.Schemas.ShiftSignups = commonSignups
share.Schemas.TaskSignups = commonSignups
share.Schemas.LeadSignups = commonSignups
