module.exports = (app) ->

  app.service 'tasksSelection', (tasksService) ->

    class Selection
      constructor: ->
        @tasks = []
      toggleSelection: (task) ->
        idx = @tasks.indexOf(task)
        if idx == -1
          @tasks.push(task)
        else
          @tasks.splice(idx, 1)
      isSelected: (task) ->
        @tasks.indexOf(task) > -1
      hasOtherSelectedThan: (task) ->
        @tasks.length > 1 or @tasks[0] != task
      deselectAll: ->
        @tasks.splice(0, @tasks.length)

      toggleBookingTask: ->
        selectionBooked = @isBooked()
        tasksToToggle = @tasks.filter (t) -> tasksService.isBooked(t) == selectionBooked
        tasksToToggle.forEach (task) ->
          tasksService.toggleBooking(task)

      toggle: ->
        nonCompleted = @tasks.filter (t) -> not t.is("completed")
        tasksToToggle = if nonCompleted.length == 0 then @tasks else nonCompleted
        tasksToToggle.forEach (task) ->
          #TODO: batch
          tasksService.toggle(task)
      isBooked: ->
        @tasks.every (t) ->tasksService.isBooked(t)
      getSelectionAsTask: ->
        nonCompleted = @tasks.filter (t) -> not t.is("completed")
        task = {}
        if (nonCompleted.length == 0)
          #all completed
          task.cost = @tasks.map((t) ->t.cost).reduce ((a,b)->a+b), 0
          task.status = "completed"
          task
        else
          #ignore completed
          task.cost = nonCompleted.map((t) ->t.cost).reduce ((a,b)->a+b), 0
          task.status = tasksService.getStatusForCost(task.cost)
        task

    createSelection: ->
      new Selection()

  #<something select-to='selection' select-with='click|ctrl-click' select='object'>
  #TODO: filter non-tasks
  app.directive 'selectTo', ->
    (scope, el, attrs) ->
      selection = scope.$eval(attrs.selectTo)
      useCtrl = attrs.selectWith == 'ctrl-click'
      el.click (e) ->
        objectToSelect = scope.$eval(attrs.select)
        selection.deselectAll() if useCtrl and not e.ctrlKey and selection.hasOtherSelectedThan(objectToSelect)
        selection.toggleSelection(objectToSelect)
        scope.$apply()

