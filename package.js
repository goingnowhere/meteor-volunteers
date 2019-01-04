/* globals Package, Npm */
Package.describe({
  name: 'abate:volunteers',
  version: '0.0.1',
  summary: 'Volunteers form',
  git: '',
  documentation: 'README.md',
})

Npm.depends({
  bootstrap: '4.0.0',
  chartjs: '0.3.24',
  'moment-range': '3.1.1',
  'moment-timezone': '0.5.23',
  react: '16.5.0',
  'react-dom': '16.5.0',
  'react-fontawesome': '1.6.1',
})

Package.onUse((api) => {
  api.versionsFrom('1.4')

  api.use([
    'mongo',
    'coffeescript',
    'ecmascript',
    'tmeasday:check-npm-versions',
    'aldeed:collection2@3.0.0',
    'aldeed:autoform@6.3.0',
    'aldeed:autoform-select2',
    'check',
    'underscore',
    'reywood:publish-composite@1.5.2',
    'piemonkey:roles',
    'reactive-dict',
    'reactive-var',
    'random',
    'iron:router',
    'universe:i18n',
    'universe:i18n-blaze',
    'abate:autoform-components',
    'abate:formbuilder',
    'mdg:validated-method',
  ], ['client', 'server'])

  api.use([
    'templating',
    'tracker',
    'fortawesome:fontawesome',
    'natestrauser:select2@4.0.3',
    'abate:autoform-datetimepicker',
    'peppelg:bootstrap-3-modal',
    'react-template-helper',
    'react-meteor-data',
  ], 'client')

  api.use([
    'jcbernack:reactive-aggregate',
  ], 'server')

  // Order Matters !
  api.add_files([
    'both/global.coffee',
    'both/router.coffee',
    'both/routerControllers.js',

    'both/collections/subSchemas.coffee',
    'both/collections/duties.coffee',
    'both/collections/unit.coffee',
    'both/collections/volunteer.coffee',
    'both/collections/timeseries.coffee',
    'both/collections/initCollections.coffee',

    'both/stats.coffee',

    'both/methods/methods.coffee',

    'api.coffee',
  ], ['server', 'client'])

  api.add_files([
    'client/global_helpers.coffee',
    'client/css/custom.css',
    'client/widgets.html',
    'client/widgets.js',

    'client/shifts/shifts.html',
    'client/shifts/shifts.coffee',
    'client/shifts/signupList.html',
    'client/shifts/signupList.coffee',

    'client/volunteers/userform.html',
    'client/volunteers/userform.coffee',
    'client/volunteers/volunteerForm.html',
    'client/volunteers/volunteerForm.coffee',
    'client/components/volunteers/BookedTable.jsx',

    'client/units/team.html',
    'client/units/team.coffee',
    'client/units/department.html',
    'client/units/department.coffee',
    'client/units/division.html',
    'client/units/division.coffee',

    'client/signups/team.html',
    'client/signups/team.coffee',
    'client/signups/signups.html',
    'client/signups/signups.js',

  ], 'client')

  api.add_files([
    'server/methods.js',
    'server/publications.coffee',
  ], 'server')

  api.add_files(['i18n/en.i18n.json'], ['client', 'server'])

  api.export(['VolunteersClass'])
})

// Package.onTest(function (api) {
//   api.use([
//     'practicalmeteor:mocha',
//     'johanbrook:publication-collector',
//     'ecmascript'
//   ]);
//
//   // Add any files with mocha tests.
//   api.addFiles('imports/tests/methods.tests.js');
// });
