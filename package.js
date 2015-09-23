Package.describe({
  name: 'sbj:clientside-image-manipulation',
  summary: 'A clientside javascript library for manipulating images before uploading.',
  version: '1.0.4',
  git: 'https://github.com/ccorcos/meteor-clientside-image-manipulation.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use(['coffeescript', 'underscore', 'cfs:micro-queue@0.0.6','reactive-var','tracker'], 'client')

  api.addFiles(['lib/exif.js', 'lib/processImage.coffee'], 'client');

  api.export('processImage', ['client'])

});
