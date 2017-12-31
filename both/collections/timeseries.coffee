import SimpleSchema from 'simpl-schema'

share.Schemas.TimeSeries = new SimpleSchema(
  timestamp: Date()
  tag1: String
  tag2: String
  tag3: String
  values: Array
  "values.$":
    type: Object
    blackbox: true
)
