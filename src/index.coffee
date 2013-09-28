{drawImageWithGrid, splitPicture, drawPuzzlePiece, loadImage, makePuzzlePiece} = require './puzzle/puzzle'

tasksService = require './tasks/tasks'

app = angular.module('puzzle', [])


app.service 'tasksService', ->
  tasksService.load()
  tasksService

updatePartVisibility = (part) -> part.visible = part.data.is 'completed'

loadPuzzle = (puzzle, project, cb) ->
  loadImage project.image, (image) ->
    puzzle.image = image
    puzzle.split = splitPicture(image.width, image.height, 10, project.tasks)
    puzzle.split.parts.forEach updatePartVisibility
    cb()


app.controller 'main', (tasksService, $scope) ->
  $scope.puzzle = {}
  $scope.project = tasksService.project
  $scope.budget = tasksService.budget
  $scope.$watch "project.id", (->
    loadPuzzle $scope.puzzle, $scope.project, ->
      $scope.$apply()
  )
  $scope.toggleTask = (part) ->
    tasksService.toggle(part.data)
    updatePartVisibility(part)

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
    scope.$parent.$watch attrs.puzzlePart, (newVal, oldVal)->
      part = newVal
      return if not part
      puzzle = scope.$parent.puzzle
      image = if attrs.puzzlePartNoImage then new Image() else puzzle.image
      scope.puzzlePartToggle = (() -> part.visible = !part.visible) if not attrs.puzzlePartToggle
      piece.remove() if piece
      piece = makePuzzlePiece(image, part.figure, attrs.puzzlePartSize).appendTo(el).show()
      if $(el).css('position') == 'absolute'
        $(el).css left: part.figure.x, top: part.figure.y

