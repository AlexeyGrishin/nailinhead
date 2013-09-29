{drawImageWithGrid, splitPicture, drawPuzzlePiece, loadImage, makePuzzlePiece} = require './puzzle/puzzle'


app = angular.module('puzzle')


updatePartVisibility = (part) -> part.visible = part.data.is 'completed'

loadPuzzle = (puzzle, project, cb) ->
  loadImage project.image, (image) ->
    puzzle.image = image
    puzzle.split = splitPicture(image.width, image.height, 10, project.tasks)
    puzzle.split.parts.forEach updatePartVisibility
    cb()


app.controller 'test', (tasksService, $scope) ->
  $scope.puzzle = {}
  $scope.project = tasksService.project
  $scope.budget = tasksService.budget
  updatePuzzle = (->
    loadPuzzle $scope.puzzle, $scope.project, ->
      $scope.$apply()
  )
  $scope.$watch "project.id", updatePuzzle
  #$scope.$watch "project.tasks.length", updatePuzzle
  $scope.toggleTask = (part) ->
    tasksService.toggle(part.data)
    updatePartVisibility(part)
  $scope.addTask = ->
    task = tasksService.addTask("New task", 33)
    $scope.puzzle.split = splitPicture($scope.puzzle.image.width, $scope.puzzle.image.height, 10, [task], $scope.puzzle.split.parts)
    $scope.puzzle.split.parts.forEach updatePartVisibility
  $scope.$watch "budget.amount", ->
    tasksService.updateStatus()

  tasksService.selectProject(tasksService.projects[0])
  $scope.$watch "puzzle.split.parts", (->
    $canvas = $("canvas.project-img")[0]
    return if not $scope.puzzle.image
    drawImageWithGrid($canvas, $scope.puzzle.image, $scope.puzzle.split)
  ), true


app.directive 'puzzlePart', ->
  replace: true
  scope:
    puzzlePart: '=puzzlePart'
    puzzlePartToggle: '&'
  template:
    """
    <div
    ng-click="puzzlePartToggle()"
    ng-class="{off: !puzzlePart.visible}"
    title="{{ puzzlePart.data.title }}"></div>
    """
  link: (scope, el, attrs) ->
    piece = null
    scope.$parent.$watch attrs.puzzlePart, ((newVal, oldVal)->
      part = newVal
      return if not part
      puzzle = scope.$parent.puzzle
      image = if attrs.puzzlePartNoImage then new Image() else puzzle.image
      scope.puzzlePartToggle = (() -> part.visible = !part.visible) if not attrs.puzzlePartToggle
      piece.remove() if piece
      piece = makePuzzlePiece(image, part.figure, attrs.puzzlePartSize).appendTo(el).show()
      if $(el).css('position') == 'absolute'
        $(el).css left: part.figure.x, top: part.figure.y
    ), true

