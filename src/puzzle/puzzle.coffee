c = require('./calc')

loadImage = (image, cb) ->
  if typeof image == 'string'
    img = new Image()
    img.src = image
    img.onload = ->
      cb(img)
  else
    cb(image)

context = (canvas) ->
  canvas.ctx = canvas.getContext("2d")
  canvas.ctx

drawImageWithGrid = (canvas, image, split) ->
  loadImage image, (image) ->
    canvas.width = image.width;
    canvas.height = image.height
    ctx = context(canvas)
    ctx.drawImage image, 0, 0
    for part in split.parts
      func = if part.visible then drawPuzzlePiece else clearPuzzlePiece
      func canvas, image, part.figure, part.figure.x, part.figure.y

clipFigure = ({ctx}, {x, y, scale}, figure, whenClip) ->
  ctx.save()
  ctx.beginPath()
  ctx.scale(scale, scale) if scale
  ctx.translate(-figure.x+x, -figure.y+y)
  figure.draw ctx
  ctx.clip()
  whenClip()
  ctx.restore()

clearPuzzlePiece = ({ctx}, image, part, x = 0, y = 0) ->
  ctx.fillStyle = "#ccc"
  ctx.beginPath()
  part.draw ctx
  ctx.fill()

toScale = (sizeScalar, newSize) ->
  newSize / sizeScalar

sizeToScale = (size, newSize) ->
  toScale Math.max(size.w, size.h), newSize


# options = {
#   x: position on canvas
#   y: position on canvas
#   size: new size (both width an height will be changed to be <= size)
# }
drawPuzzlePiece = (canvas, image, part, options = {x:0, y:0}) ->
  loadImage image, (image) ->
    clipOpts = {x: options.x, y: options.y}
    clipOpts.scale = sizeToScale part, options.size if options.size
    clipFigure canvas, clipOpts, part, ->
      canvas.ctx.drawImage image, 0, 0
      canvas.ctx.strokeStyle = "#444"
      canvas.ctx.beginPath()
      part.draw canvas.ctx
      canvas.ctx.stroke()

makePuzzlePiece = (image, part, newSize) ->
  $canvas = $("<canvas></canvas>").hide().appendTo($("body"))
  canvas = $canvas[0]
  context(canvas)
  loadImage image, (image) ->
    canvas.width = newSize ? part.w
    canvas.height = newSize ? part.h
    drawPuzzlePiece canvas, image, part, {x:0, y:0, size: newSize}
  $canvas


module.exports = {
  splitPicture: c.splitPicture.bind(c)
  drawPuzzlePiece
  drawImageWithGrid
  loadImage
  makePuzzlePiece
}