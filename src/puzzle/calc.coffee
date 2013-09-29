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
    configuration[BOTTOM] = PLAIN if row == rows - 1 or (row == rows - 2 and lastCol > 0 && col >= lastCol) or idx == count - 1
    configuration[LEFT] = PLAIN if col == 0
    configuration[RIGHT] = PLAIN if col == cols - 1 or idx == count - 1

  puzzleMap = [0...rows].map -> [0...cols].map -> {}
  items.forEach ({col, row}) ->
    puzzleMap[row][col].bottom = random()
    puzzleMap[row][col].right = random()
  items.map (item, idx) ->
    row = item.row
    col = item.col
    configuration = ["-","-","-","-"]
    configuration[BOTTOM] = puzzleMap[row][col].bottom
    configuration[TOP] = invert(puzzleMap[row-1][col].bottom) if row > 0
    configuration[RIGHT] = puzzleMap[row][col].right
    configuration[LEFT] = invert(puzzleMap[row][col-1].right) if col > 0
    checkCorner configuration, row, col, idx
    console.log "#{item.data.title} at #{row}, #{col}, #{col == cols-1}, #{configuration.join('')}"
    configuration = configuration.join("")
    {col, row, configuration}


fitInSquare = (parts) ->
  parts = parts.length if parts.length isnt undefined
  sq = Math.ceil(Math.sqrt(parts))
  cols = sq
  rows = Math.ceil(parts / cols)
  return {cols, rows}


distributePartsOnPicture = (newObjects, oldParts = [], oldCols = 0, oldRows = 0) ->
  {cols, rows} = fitInSquare oldParts.length + newObjects.length
  # new parts shall be distributed in new col/row
  busyCells = []
  oldParts.forEach ({col, row}) ->
    busyCells[row] = busyCells[row] ? []
    busyCells[row][col] = true

  parts = oldParts.slice()
  objects = newObjects.slice()
  addToNewRowOrCol = cols > oldCols or rows > oldRows
  [0...rows].forEach (row) ->
    return if objects.length == 0
    [0...cols].forEach (col) ->
      return if objects.length == 0
      return if busyCells[row]?[col]
      return if addToNewRowOrCol and row < oldRows and col < oldCols
      #console.log "Locate object #{objects[0].title} at #{col},#{row}"
      parts.push {
        data: objects.shift()
        row: row
        col: col
      }
  throw new Error("Cannot locate objects: #{objects}") if objects.length > 0
  cols: cols
  rows: rows
  parts: parts



splitPicture = (width, height, pad, objects, oldParts = []) ->
  squareGenerator = (rows, cols, objects) ->
    (x, y, partSize, col, row) ->
      square(x, y, partSize)

  puzzleGenerator = (rows, cols, objects) ->
    puzzleItems = generatePuzzle(rows, cols, objects)
    (x, y, partSize, col, row) ->
      puzzle p(x,y), size(partSize, partSize), partSize/4, puzzleItems.filter((pi)-> pi.col == col and pi.row == row)[0].configuration

  generator = puzzleGenerator

  realwidth = width - 2*pad
  realheight = height - 2*pad
  oldCols = 1 + Math.max.apply(null, oldParts.map (o) -> o.col) ? 0
  oldRows = 1 + Math.max.apply(null, oldParts.map (o) -> o.row) ? 0
  {cols, rows, parts} = distributePartsOnPicture objects, oldParts, oldCols, oldRows
  partSize = Math.min(realwidth / cols, realheight / rows)
  startx = (realwidth - partSize * cols) / 2 + pad
  starty = (realheight - partSize * rows) / 2 + pad
  generateFigure = generator(rows, cols, parts)
  size: partSize
  parts: parts.map (part, idx) ->
    part.figure = generateFigure(part.col*partSize + startx, part.row*partSize + starty, partSize, part.col, part.row)
    part

module.exports =
  p: p
  size: size
  splitPicture: splitPicture
