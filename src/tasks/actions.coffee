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
      scope.$watch(scope.selection.$watch(), ->
        scope.taskBooked = scope.selection.isBooked()
        scope.task = scope.selection.getSelectionAsTask()
      ,true)

  app.directive 'taskActionsList', () ->
    restrict: 'E'
    replace: true
    scope:
      task: "="
      booking: "="
    templateUrl: "actions.html"
    link: (scope, el, attrs) ->
      scope.options = scope.$parent.options
      scope.toggleBooked = -> scope.booking.toggle(scope.task)
        #TODO[booked*] tasksService.toggleBooking(scope.task)
      scope.toggleTask = ->
        scope.task.toggle()
      scope.$watch (-> scope.booking.include?(scope.task)), (newVal) ->
        scope.taskBooked = newVal
