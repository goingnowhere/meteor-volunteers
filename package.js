/* globals Package, Npm */
Package.describe({
  name: 'goingnowhere:volunteers',
  version: '0.0.2',
  summary: 'Meteor volunteer management module',
  git: 'https://github.com/goingnowhere/meteor-volunteers',
  documentation: 'README.md',
})

Npm.depends({
  bootstrap: '4.3.1',
  'chart.js': '2.8.0',
  'react-chartjs-2': '2.9.0',
  'moment-range': '4.0.2',
  'moment-timezone': '0.5.23',
  // Depends on React but if we specify that Meteor bundles a copy of React with the package
  // which causes problems, so we just hope the client has it instead.
  // react: '16.8.6',
  // 'react-dom': '16.8.6',
  '@fortawesome/fontawesome-svg-core': '6.2.1',
  // '@fortawesome/free-regular-svg-icons': '6.2.1',
  '@fortawesome/free-solid-svg-icons': '6.2.1',
  '@fortawesome/react-fontawesome': '0.2.0',
  'react-modal': '3.8.1',
})

Package.onUse((api) => {
  api.versionsFrom('2.4')

  api.use([
    'mongo',
    'ecmascript',
    'tmeasday:check-npm-versions',
    'aldeed:collection2@3.0.2',
    'aldeed:autoform@6.3.0',
    'aldeed:autoform-select2',
    'check',
    'underscore',
    'reywood:publish-composite@1.7.0',
    'alanning:roles',
    'reactive-dict',
    'reactive-var',
    'random',
    'universe:i18n',
    'universe:i18n-blaze',
    'abate:autoform-components',
    'mdg:validated-method',
    'react-meteor-data',
    'gadicc:blaze-react-component',
  ], ['client', 'server'])

  api.use([
    'templating',
    'tracker',
    'fortawesome:fontawesome',
    'natestrauser:select2@4.0.3',
    'abate:autoform-datetimepicker',
    'peppelg:bootstrap-3-modal',
    'react-template-helper',
    'themeteorchef:bert',
  ], 'client')

  api.use([
    'jcbernack:reactive-aggregate',
  ], 'server')

  api.addFiles([
    'client/globalHelpers.js',
    'client/css/custom.css',

    'client/shifts/shifts.html',
    'client/shifts/shifts.js',
  ], 'client')

  api.addFiles(['i18n/en.i18n.json'], ['client', 'server'])

  api.mainModule('api.js')
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
