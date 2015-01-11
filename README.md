# Meteor Clientside Image Manipulation

This package was born out of the necessity to process images before uploading them to the server. 

One problem is that browsers do not render images with the correct orientation based on EXIF metadata. Another problem this package solves is reducing the size of images before uploading. 

All of the code in this package comes from [this tutorial](http://chariotsolutions.com/blog/post/take-and-manipulate-photo-with-web-page/).

## Usage

    meteor add ccorcos:clientside-image-manipulation

Then if you want to use it with [CollectionFS](https://github.com/CollectionFS/Meteor-CollectionFS), all you have to do is pipe things through the `processImage` function:


    Template.upload.events
      'change #image-upload': (e,t) ->
        file = e.target.files[0]
        if not file? then return

        # processImage(file, maxWidth, maxHeight, callback(dataURI))
        data = processImage file, 300, 300, (data) ->
          img = new FS.File(data)

          img.metadata =  
            date: Date.now()
            ownerId: Meteor.userId()

          Images.insert img,  (err, fileObj) ->
            if err
              console.log err

