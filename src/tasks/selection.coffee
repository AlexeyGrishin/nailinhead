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
        #for each - toggle booking
      toggle: ->
        #for each - toggle,

      isBooked: ->
        @tasks.every (t) ->tasksService.isBooked(t)
      getSelectionAsTask: ->
        completed = @tasks.filter (t) ->t.is("completed")
        nonCompleted = @tasks.filter (t) -> not t.is("completed")
        task = {}
        if (completed.length == @tasks.length)
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

