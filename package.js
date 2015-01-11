Package.describe({
  name: 'ccorcos:clientside-image-manipulation',
  summary: 'A clientside javascript library for manipulating images before uploading then. Specifically, resizing and adjusting for image orientation.',
  version: '1.0.0',
  git: 'https://github.com/ccorcos/meteor-clientside-image-manipulation.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use(['coffeescript'], 'client')

  api.addFiles(['lib/binaryFile.js', 'lib/exif.js', 'lib/processImage.coffee'], 'client');

  api.export('processImage', ['client'])

});

// Package.onTest(function(api) {
//   api.use('tinytest');
//   api.use('ccorcos:swipe');
//   api.addFiles('ccorcos:swipe-tests.js');
// });
