module.exports = (app) ->

  app.directive 'taskSelectionList', () ->
    restrict: 'E'
    replace: true
    scope:
      selection: "=selection"
    templateUrl: "actions.html"
    link: (scope, el, attrs) ->
      scope.options = scope.$parent.options
      scope.toggleBooked = ->
        scope.selection.toggleBookingTask()
      scope.toggleTask = ->
        scope.selection.toggle()
        scope.selection.deselectAll() if (attrs.autoClose isnt undefined)
      scope.$watch("selection", ->
        scope.taskBooked = scope.selection.isBooked()
        scope.task = scope.selection.getSelectionAsTask()
      ,true)

  app.directive 'taskActionsList', (tasksService) ->
    restrict: 'E'
    replace: true
    scope:
      task: "="
    templateUrl: "actions.html"
    link: (scope, el, attrs) ->
      scope.options = scope.$parent.options
      scope.toggleBooked = ->
        tasksService.toggleBooking(scope.task)
      scope.toggleTask = ->
        tasksService.toggle(scope.task)
      scope.$watch "task.groups", ->
        scope.taskBooked = tasksService.isBooked(scope.task)
