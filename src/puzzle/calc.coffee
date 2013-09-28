p = (x,y) -> {x,y}
size = (w,h) -> {w,h}

rectangle = (p1, sz) ->
  x: p1.x
  y: p1.y
  w: sz.w
  h: sz.h
  resize: (delta) ->
    rectangle(p(@x-delta, @y-delta), size(@w+delta, @h+delta))
  draw: (ctx) ->
    ctx.rect @x, @y, @w, @h

square = (x, y, s) -> rectangle(p(x,y), size(s,s))

drawSquareWithPattern = (ctx, leftTop, size, pattern) ->
  ctx.save()
  ctx.translate leftTop.x, leftTop.y
  pattern(ctx, "top")
  ["right", "bottom", "left"].forEach (dir, idx) ->
    ctx.translate size, 0
    ctx.rotate Math.PI / 2
    pattern(ctx, dir)
  ctx.restore()

PLAIN = "-"
IN = "_"
OUT = "^"
[LEFT, TOP, RIGHT, BOTTOM] = [0,1,2,3]

# configuration = "-^-_"
puzzle = (p1, sz, sizeOfPad, configuration = "^_^_") ->
  delta =
    "_": sizeOfPad
    "^": -sizeOfPad
    "-": 0
  [left, top, right, bottom] = configuration
  throw new Error("Cannot create puzzle for non-square size: #{sz}") if sz.w != sz.h
  obj =
    x: p1.x
    y: p1.y
    w: sz.w
    h: sz.h
    resize: (delta) ->
      puzzle(p(p1.x-delta, p1.y-delta), size(sz.w+delta, sz.h+delta), sizeOfPad+delta, configuration)
    draw: (ctx) ->
      edgeSize = sz.w
      padFromCorner = (edgeSize - sizeOfPad*2) / 2
      ctx.save()
      #ctx.translate -(@x - p1.x), -(@y - p1.y)
      drawSquareWithPattern ctx, p1, edgeSize, (ctx, dir) ->
        ctx.moveTo(0, 0) if dir == "top"
        ctx.lineTo(padFromCorner, 0)
        dy = delta[{left, top, right, bottom}[dir]]
        ctx.arcTo(padFromCorner, dy, edgeSize/2, dy, sizeOfPad)
        ctx.arcTo(edgeSize - padFromCorner, dy, edgeSize - padFromCorner, 0, sizeOfPad)
        ctx.lineTo(edgeSize, 0)
      ctx.restore()

  onOut = (val) ->
    addW: -> obj.w += sizeOfPad if val == OUT; @
    addH: -> obj.h += sizeOfPad if val == OUT; @
    shiftX: -> obj.x -= sizeOfPad if val == OUT; @
    shiftY: -> obj.y -= sizeOfPad if val == OUT; @

  onOut(left).addW().shiftX()
  onOut(right).addW()
  onOut(top).addH().shiftY()
  onOut(bottom).addH()

  obj


generatePuzzle = (rows, cols, items) ->
  count = items.length
  invert = (o) ->
    switch o
      when OUT then IN
      when IN then OUT
      else PLAIN
  random = -> [IN, OUT][Math.round(Math.random())]
  lastCol = items.length % cols
  checkCorner = (configuration, row, col, idx) ->
    configuration[TOP] = PLAIN if row == 0
    configuration[BOTTOM] = PLAIN if row == rows - 1 or (row == rows - 2 and lastCol > 0 && col >= lastCol)
    configuration[LEFT] = PLAIN if col == 0
    configuration[RIGHT] = PLAIN if col == cols - 1 or idx == count - 1

  puzzleMap = [0...rows].map -> [0...cols].map -> {}
  items.map (item, idx) ->
    row = Math.floor(idx / cols)
    col = idx % cols
    puzzleMap[row][col].bottom = random()
    puzzleMap[row][col].right = random()
    configuration = ["-","-","-","-"]
    configuration[BOTTOM] = puzzleMap[row][col].bottom
    configuration[TOP] = invert(puzzleMap[row-1][col].bottom) if row > 0
    configuration[RIGHT] = puzzleMap[row][col].right
    configuration[LEFT] = invert(puzzleMap[row][col-1].right) if col > 0
    checkCorner configuration, row, col, idx
    configuration = configuration.join("")
    {col, row, configuration, idx}


fitInSquare = (parts) ->
  sq = Math.ceil(Math.sqrt(parts.length))
  cols = sq
  rows = Math.ceil(parts.length / cols)
  return {cols, rows}


splitPicture = (width, height, pad, parts) ->
  squareGenerator = (rows, cols, parts) ->
    (x, y, partSize, idx) ->
      square(x, y, partSize)

  puzzleGenerator = (rows, cols, parts) ->
    puzzleItems = generatePuzzle(rows, cols, parts)
    (x, y, partSize, idx) ->
      puzzle p(x,y), size(partSize, partSize), partSize/4, puzzleItems[idx].configuration

  generator = puzzleGenerator

  realwidth = width - 2*pad
  realheight = height - 2*pad
  {cols, rows} = fitInSquare parts
  partSize = Math.min(realwidth / cols, realheight / rows)
  startx = (realwidth - partSize * cols) / 2 + pad
  starty = (realheight - partSize * rows) / 2 + pad
  generateFigure = generator(rows, cols, parts)
  size: partSize
  parts: parts.map (part, idx) ->
    y = Math.floor(idx / cols)
    x = idx % cols
    data: part
    figure: generateFigure x*partSize + startx, y*partSize + starty, partSize, idx

###
$ ->
  cv = $("<canvas></canvas>").prependTo($("body"))
  ctx = cv[0].getContext("2d")
  drawPuzzle = (x, y, color, config) ->
    ctx.beginPath()
    ctx.fillStyle = color
    puzzle(p(x, y), size(20, 20), 5, config).draw ctx
    ctx.fill()
  items = [0...3]
  {rows, cols} = fitInSquare items
  color = ["red", "blue", "green", "gold"]
  generatePuzzle(rows, cols, items).forEach ({col, row, idx, configuration}) ->
    drawPuzzle col*20, row*20, color[idx%color.length], configuration
###

module.exports =
  p: p
  size: size
  splitPicture: splitPicture
