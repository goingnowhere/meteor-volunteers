# temporary fix till TAPi18n is compatible with node-simple-schema
Template.registerHelper "_", (p) -> TAPi18n.__ p
