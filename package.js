Package.describe({
  name: 'abate:volunteers',
  version: '0.0.1',
  summary: 'Volunteers form',
  git: '',
  documentation: 'README.md',
});

Npm.depends({
  'flatpickr':'2.4.8'
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
    'aldeed:autoform@6.0.0',
    'aldeed:autoform-select2',
    'alanning:roles@1.2.15',
    'check',
    'underscore',
    'benmgreene:moment-range',
    'momentjs:moment',
    'reactive-dict',
    'reactive-var',
    'random',
    'matb33:collection-hooks',
    'abate:formbuilder'
  ], ['client', 'server']);

  api.use( [
    'templating',
    // 'tracker',
    'twbs:bootstrap',
    'fortawesome:fontawesome',
    'abate:autoform-components',
    'natestrauser:select2@4.0.3',
    'zimme:select2-bootstrap3-css',
    'drewy:datetimepicker',
    'drewy:autoform-datetimepicker',
    // 'drblue:fullcalendar',
  ], 'client');

  api.use( [
    'peerlibrary:server-autorun',
  ], 'server');

  api.add_files([
    'both/global.coffee',
    "both/teams.coffee",
    "both/volunteer.coffee",
    "api.coffee"
  ], ["server","client"]);

  // api.add_files([ 'package-tap.i18n', ], ['client', 'server']);
  api.add_files([
    'client/global_helpers.coffee',
    // 'client/css/awesome-bootstrap-checkbox.css',
    'client/css/custom.css',
    "client/frontend/filters.html",
    "client/frontend/filters.coffee",
    "client/frontend/volunteer.html",
    "client/frontend/volunteer.coffee",

    "client/backend/volunteer.html",
    "client/backend/volunteer.coffee",
    "client/backend/tasks.html",
    "client/backend/tasks.coffee",
    "client/backend/shifts.html",
    "client/backend/shifts.coffee",
    "client/backend/teams.html",
    "client/backend/teams.coffee",
  ], "client");

  api.add_files([
    'server/volunteer.coffee',
    'server/teams.coffee',
    'server/publications.coffee'
  ],"server");

  // api.add_files([ "i18n/en.i18n.json", ], ["client", "server"]);

  api.export([ 'Volunteers' ]);
});

//Package.onTest(function(api) {
  //api.use('ecmascript');
  //api.use('tinytest');
  //api.use('i18n-inline');
  //api.mainModule('i18n-inline-tests.js');
//});
