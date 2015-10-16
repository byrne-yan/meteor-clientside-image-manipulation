
img_process_queue = new MicroQueue false
processing_pixels = new ReactiveVar 0

processImage = (imageFile, rest...) ->
  console.time 'processImage'
  console.time 'processImage-async'
  __processImage imageFile, rest...
  console.timeEnd 'processImage'

__processImage = (imageFile, rest...) ->
  callback = rest[rest.length-1]
  if not _.isFunction(callback) then console.log "ERROR: you need to pass a callback function to processImage"

  maxHeight = undefined
  maxWidth = undefined
  quality = undefined
  exif = undefined
  if rest.length is 2
    options = rest[0]
    maxWidth = options.maxWidth
    maxHeight = options.maxHeight
    quality = options.quality
    exif = options.exif
#  console.log "exif:"+exif

#  if exif and exif.ImageHeight*exif.ImageWidth< 200*200

  img_process_queue.insert Date.now(),[imageFile,maxWidth,maxHeight,quality,exif,callback];


doProcess = (args) ->
  imageFile = args[0]
  maxWidth = args[1]
  maxHeight = args[2]
  quality = args[3]
  exif = args[4]
  callback = args[5]

  canvas = document.createElement('canvas')
  ctx = canvas.getContext("2d")
  img = new Image()
  if exif
    img.exif = exif
    img.estimatePixels = exif.ImageHeight*exif.ImageWidth
  else
    img.estimatePixels = 3600*2400

  processing_pixels.set processing_pixels.get()+img.estimatePixels
  img.crossOrigin = 'anonymous'

  process = (exif) ->
#    console.log "start process"+ Date.now()
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

    console.log "transform,width,height", transform, width, height

    if maxWidth and maxHeight
      if width / maxWidth > height / maxHeight
        if width > maxWidth
          height *= maxWidth / width
          width = maxWidth
      else
        if height > maxHeight
          width *= maxHeight / height
          height = maxHeight
    width = Math.floor width
    height = Math.floor height
    canvas.width = width
    canvas.height = height
#    ctx.fillStyle = "white"
#    ctx.fillRect 0, 0, canvas.width, canvas.height
#    ctx.clearRect 0,0,canvas.width, canvas.height #faster
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
#    pixels = ctx.getImageData(0, 0, canvas.width, canvas.height)

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

#    ctx.putImageData pixels, 0, 0


    if quality
      data = canvas.toDataURL("image/jpeg", quality)
    else
      data = canvas.toDataURL("image/jpeg")

#    console.log "done process"+ Date.now()

#    pixels = null
    nPixels = img.estimatePixels
    img = null
    ctx = null
    canvas = null
    console.timeEnd 'processImage-async'
    callback data, width, height
    processing_pixels.set processing_pixels.get()-nPixels

  loadUri2Img = (imageFile, img ) ->
    window.resolveLocalFileSystemURL imageFile, (fileEntry) ->
#      console.log fileEntry
      fileEntry.file (file) ->
        reader = new FileReader()
        reader.onerror = (e) ->
          console.log "file loading error:", e
          processing_pixels.set processing_pixels.get()-img.estimatePixels
        reader.onload = (e) ->
#          console.log "image loaded:"+ Date.now()
          content = e.target.result
          delete e.target #release memory
          img.src = content
        reader.readAsDataURL(file)
      , (error) -> console.log error
    , (error) -> console.log error

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
#          console.log 'file://* fixed for meteor cordova'
          category = 'dataURI'
          loadUri2Img imageFile, img
        else
          category = 'URL'
          img.src = imageFile
      else
        category = 'URL'
        img.src = imageFile
  else if window.FileReader && (imageFile instanceof window.Blob || imageFile instanceof window.File)
    category = 'File'
    img.src = url.createObjectURL(imageFile)

  img.onload = (e) ->
#    console.log "onload:"+ Date.now(), e.target.exif

    if e.target.exif
      if category == 'File' then url.revokeObjectURL @src
      process e.target.exif
    else
#      console.log "EXIF.getData:"+ Date.now()
      EXIF.getData　e.target, () ->
        if category == 'File' then url.revokeObjectURL @src
        process img.exifdata

Tracker.autorun ()->
  if (img_process_queue.length() >0 and (!Meteor.isCordova or processing_pixels.get() < 2*2000*2000))
    doProcess img_process_queue.getFirstItem()

Tracker.autorun ()->
  console.log "image processing:"+processing_pixels.get()
