
class Budget
  constructor: (@amount) ->
  set: (@amount) ->
  increase: (delta) -> @set @amount + delta
  decrease: (delta) -> @set @amount - delta

  isEnoughFor: (money) ->
    money <= @amount



class Task
  constructor: (@title, @cost = 0, @status = "") ->

  complete: (budget) ->
    return if @status is "completed"
    throw new Error("Task '#{@title}' cannot be done") if @status is not "available"
    @status = "completed"
    budget.decrease @cost

  updateStatus: (budget) ->
    return if @status is "completed"
    @status = if budget.isEnoughFor(@cost) then "available" else "unavailable"

  revert: (budget) ->
    throw new Error("Task '#{@title}' cannot be undone - it is not completed") if @status is not "completed"
    @status = ""
    budget.increase @cost
    @updateStatus budget

  is: (status) -> @status == status

task = (title, cost, status) -> new Task(title, cost, status)

TasksService =
  project: {}
  budget: new Budget(250)

  load: ->
    @projects = [{
      id: 1,
      name: "Puzzle project",
      image: "/img/pic1.jpg",
      tasks: [
        task("Create puzzle control", 0, "completed"),
        task("Make project page", 200),
        task("Make projects list", 500),
        task("Update styles", 251),
      ]
    }]

  selectProject: (project) ->
    for name, value of project
      @project[name] = value

  unselectProject: ->
    @project = null

  updateStatus: ->
    return if not @project
    @project.tasks.forEach (t)=>t.updateStatus(@budget)

  toggle: (task) ->
    if task.is "completed"
      task.revert @budget
    else if task.is "available"
      task.complete @budget
    else
      throw new Error "not.available"


  setBudget: (newValue) ->
    @budget.set newValue
    @updateStatus()

module.exports = TasksService



