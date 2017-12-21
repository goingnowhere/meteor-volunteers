Package.describe({
  name: 'abate:volunteers',
  version: '0.0.1',
  summary: 'Volunteers form',
  git: '',
  documentation: 'README.md',
});

Npm.depends({
  'flatpickr':'2.4.8',
  'jquery': '3.2.1',
  'bootstrap': '3.3.7'
// "awesome-bootstrap-checkbox": "1.0.0-alpha.4"
});

Package.onUse(function(api) {
  api.versionsFrom('1.4');

  api.use([
    'mongo',
    'coffeescript',
    'ecmascript',
    'tmeasday:check-npm-versions',
    // 'tap:i18n@1.8.2',
    'aldeed:collection2-core',
    'aldeed:autoform@6.2.0',
    'aldeed:autoform-select2',
    'ostrio:autoform-files',
    'ostrio:files',
    'check',
    'underscore',
    'benmgreene:moment-range',
    'momentjs:moment',
    'piemonkey:roles',
    'reactive-dict',
    'reactive-var',
    'random',
    'iron:router',
    'abate:autoform-components',
    'abate:formbuilder'
  ], ['client', 'server']);

  api.use( [
    'templating',
    'tracker',
    'fortawesome:fontawesome',
    'natestrauser:select2@4.0.3',
    'drewy:datetimepicker',
    'abate:autoform-datetimepicker',
    // 'drblue:fullcalendar',
  ], 'client');

  // Order Matters !
  api.add_files([
    'both/global.coffee',
    'both/router.coffee',
    'both/routerControllers.js',

    "both/collections/duties.coffee",
    "both/collections/unit.coffee",
    "both/collections/volunteer.coffee",
    "both/collections/initCollections.coffee",

    'both/methods/methods.coffee',

    "api.coffee"
  ], ["server","client"]);

  // api.add_files([ 'package-tap.i18n', ], ['client', 'server']);
  api.add_files([
    'client/global_helpers.coffee',
    // 'client/css/awesome-bootstrap-checkbox.css',
    'client/css/custom.css',
    "client/frontend/filters.html",
    "client/frontend/filters.coffee",
    "client/frontend/shifts.html",
    "client/frontend/shifts.coffee",
    "client/frontend/volunteer.html",
    "client/frontend/volunteer.coffee",

    "client/backend/forms/volunteer.html",
    "client/backend/forms/volunteer.coffee",
    "client/backend/forms/tasks.html",
    "client/backend/forms/tasks.coffee",
    "client/backend/forms/shifts.html",
    "client/backend/forms/shifts.coffee",
    "client/backend/forms/leads.html",
    "client/backend/forms/leads.coffee",

    "client/backend/forms/team.html",
    "client/backend/forms/team.coffee",
    "client/backend/forms/department.html",
    "client/backend/forms/department.coffee",
    "client/backend/forms/division.html",
    "client/backend/forms/division.coffee",
    "client/backend/forms/orgUnit.html",
    "client/backend/forms/orgUnit.js",

    "client/backend/views/team.html",
    "client/backend/views/team.coffee",
    "client/backend/views/signups.html",
    "client/backend/views/signups.js",
  ], "client");

  api.add_files([
    'server/publications.coffee'
  ],"server");

  // api.add_files([ "i18n/en.i18n.json", ], ["client", "server"]);

  api.export([ 'VolunteersClass']);
});

//Package.onTest(function(api) {
  //api.use('ecmascript');
  //api.use('tinytest');
  //api.use('i18n-inline');
  //api.mainModule('i18n-inline-tests.js');
//});
