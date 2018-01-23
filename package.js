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
  'bootstrap': '4.0.0-beta.3',
  // 'popper.js': '1.12.9',
});

Package.onUse(function(api) {
  api.versionsFrom('1.4');

  api.use([
    'mongo',
    'coffeescript',
    'ecmascript',
    'tmeasday:check-npm-versions',
    'aldeed:collection2-core',
    'aldeed:autoform@6.2.0',
    'aldeed:autoform-select2',
    'ostrio:autoform-files',
    'ostrio:files',
    'check',
    'underscore',
    'momentjs:moment',
    'reywood:publish-composite',
    'piemonkey:roles',
    'reactive-dict',
    'reactive-var',
    'random',
    'iron:router',
    'universe:i18n',
    'universe:i18n-blaze',
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
    'peppelg:bootstrap-3-modal',
  ], 'client');

  // Order Matters !
  api.add_files([
    'both/global.coffee',
    'both/router.coffee',
    'both/routerControllers.js',

    "both/collections/duties.coffee",
    "both/collections/unit.coffee",
    "both/collections/volunteer.coffee",
    "both/collections/timeseries.coffee",
    "both/collections/initCollections.coffee",

    'both/methods/methods.coffee',

    "api.coffee"
  ], ["server","client"]);

  api.add_files([
    'client/global_helpers.coffee',

    "client/shifts/filters.html",
    "client/shifts/filters.coffee",
    "client/shifts/shifts.html",
    "client/shifts/shifts.coffee",
    "client/shifts/volunteer.html",
    "client/shifts/volunteer.coffee",

    "client/volunteers/volunteers.html",
    "client/volunteers/volunteers.coffee",
    "client/volunteers/userform.html",
    "client/volunteers/userform.coffee",
    "client/volunteers/volunteerForm.html",
    "client/volunteers/volunteerForm.coffee",

    "client/units/team.html",
    "client/units/team.coffee",
    "client/units/department.html",
    "client/units/department.coffee",
    "client/units/division.html",
    "client/units/division.coffee",

    "client/signups/team.html",
    "client/signups/team.coffee",
    "client/signups/signups.html",
    "client/signups/signups.js",

    "client/stats.coffee",
  ], "client");

  api.add_files([
    'server/publications.coffee',
  ],"server");

  api.add_files([ "i18n/en.i18n.json", ], ["client", "server"]);

  api.export([ 'VolunteersClass']);
});

//Package.onTest(function(api) {
  //api.use('ecmascript');
  //api.use('tinytest');
  //api.use('i18n-inline');
  //api.mainModule('i18n-inline-tests.js');
//});
