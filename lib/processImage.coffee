
# processImage = (imageFile, maxWidth, maxHeight, callback) ->
processImage = (imageFile, rest...) ->
  callback = rest[rest.length-1]
  if not _.isFunction(callback) then console.log "ERROR: you need to pass a callback function to processImage"

  maxHeight = undefined
  maxWidth = undefined
  quality = undefined
  
  if rest.length is 3 or 4
    maxWidth = rest[0]
    maxHeight = rest[1]
    if rest.length is 4
      quality = rest[2]
    
    
  canvas = document.createElement('canvas')
  ctx = canvas.getContext("2d")
  img = new Image()
  img.crossOrigin = 'anonymous'
  objectURLToBlob = (url, callback) ->
    http = new XMLHttpRequest()
    http.open "GET", url, true
    http.responseType = "blob"
    http.onload = (e) ->
      if this.status == 200 || this.status == 0
        callback(this.response)
    http.send()

  process = (exif) ->
    transform = "none"
#    console.log exif
#    console.log img.height, img.width
    if exif.Orientation is 8
      width = img.height
      height = img.width
      transform = "left"
    else if exif.Orientation is 6
      width = img.height
      height = img.width
      transform = "right"
    else if exif.Orientation is 1
      width = img.width
      height = img.height
    else if exif.Orientation is 3
      width = img.width
      height = img.height
      transform = "flip"
    else
      width = img.width
      height = img.height

    if maxWidth and maxHeight
      if width / maxWidth > height / maxHeight
        if width > maxWidth
          height *= maxWidth / width
          width = maxWidth
      else
        if height > maxHeight
          width *= maxHeight / height
          height = maxHeight

    canvas.width = width
    canvas.height = height
    ctx.fillStyle = "white"
    ctx.fillRect 0, 0, canvas.width, canvas.height
    if transform is "left"
      ctx.setTransform 0, -1, 1, 0, 0, height
      ctx.drawImage img, 0, 0, height, width
    else if transform is "right"
      ctx.setTransform 0, 1, -1, 0, width, 0
      ctx.drawImage img, 0, 0, height, width
    else if transform is "flip"
      ctx.setTransform 1, 0, 0, -1, 0, height
      ctx.drawImage img, 0, 0, width, height
    else
      ctx.setTransform 1, 0, 0, 1, 0, 0
      ctx.drawImage img, 0, 0, width, height
    ctx.setTransform 1, 0, 0, 1, 0, 0


# process into an image
    pixels = ctx.getImageData(0, 0, canvas.width, canvas.height)

# filter out the greenscreen!
# r = undefined
# g = undefined
# b = undefined
# i = undefined
# py = 0

# for py in [0...pixels.height]
#   for px in [0...pixels.width]
#     i = (py * pixels.width + px) * 4
#     r = pixels.data[i]
#     g = pixels.data[i + 1]
#     b = pixels.data[i + 2]
#     pixels.data[i + 3] = 0  if g > 100 and g > r * 1.35 and g > b * 1.6

    ctx.putImageData pixels, 0, 0

    if quality
      data = canvas.toDataURL("image/jpeg", quality)
    else
      data = canvas.toDataURL("image/jpeg")

    callback(data)

  url = window.URL || window.webkitURL
  if typeof imageFile == 'string'
    if /^data\:/i.test(imageFile) # Data URI
      category = 'dataURI'
      img.src = imageFile
    else if /^blob\:/i.test(imageFile) # Object URL
      category = 'objectURL'
      img.src = imageFile
    else
      if /^file\:/i.test(imageFile)
        if Meteor && Meteor.isCordova #fix for meteor that does not support file://
          console.log 'file://* fixed for meteor cordova'
          category = 'dataURI'
          window.resolveLocalFileSystemURL imageFile, (fileEntry) ->
            console.log fileEntry
            fileEntry.file (file) ->
              reader = new FileReader()
              reader.onloadend = (result) ->
                if reader.error
                  console.log reader.error
                else
                  img.src = reader.result
              reader.readAsDataURL(file)
            , (error) -> console.log error
          , (error) -> console.log error

        else
          category = 'URL'
          img.src = imageFile
      else
        category = 'URL'
        img.src = imageFile
  else if window.FileReader && (imageFile instanceof window.Blob || imageFile instanceof window.File)
    category = 'File'
    img.src = url.createObjectURL(imageFile)

  img.onload = () ->
    EXIF.getData　img,() ->
      if category == 'File' then url.revokeObjectURL @src
      process img.exifdata

#  img.onload = () ->
#    switch category
#      when 'dataURI'
#        exif = EXIF.readFromBinaryFile arrayBuffer
#
#    arrayBuffer = base64ToArrayBuffer(imageFile)
#        process arrayBuffer
#      when 'objectURL'
#        fileReader = new FileReader()
#        fileReader.onload = (e) -> process e.target.result
#        objectURLToBlob imageFile, blob -> fileReader.readAsArrayBuffer blob
#      when 'URL'
#        console.log img.currentSrc, img.crossOrigin
#        http = new XMLHttpRequest()
#        http.onload = ()  ->
#          if this.status == 200 || this.status == 0
#            console.log http.response
#            process　http.response
#          else
#            console.log this.status
#            throw "Could not load image"
#          http = null
#        http.onprogress = (e) ->
#          console.log e, e.type, e.loaded,'/', e.total
#        http.open "GET", imageFile, true
#        http.responseType = "arraybuffer"
##        http.setRequestHeader 'Origin',"*" #window.location.origin
#        http.send null
#      when 'File'
#        url.revokeObjectURL @src
#        fileReader = new FileReader()
#        fileReader.onload = (e) ->
#          process e.target.result
#        fileReader.readAsArrayBuffer imageFile
#      else
#        throw new Error('unknown image')