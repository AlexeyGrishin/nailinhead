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

