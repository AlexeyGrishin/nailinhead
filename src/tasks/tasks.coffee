
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
    return @ if @status is "completed"
    @status = if budget.isEnoughFor(@cost) then "available" else "unavailable"
    @

  revert: (budget) ->
    throw new Error("Task '#{@title}' cannot be undone - it is not completed") if @status is not "completed"
    @status = ""
    budget.increase @cost
    @updateStatus budget

  is: (status) -> @status == status

task = (title, cost, status) -> new Task(title, cost, status)

parseString = (str, cost) ->
  return {name:str, cost:cost} if cost isnt undefined
  if str.indexOf(',') != -1 or str.indexOf(' ') != -1
    ci = Math.max str.lastIndexOf(','), str.lastIndexOf(' ')

    probablyCost = parseFloat(str.substring(ci+1).replace(/[^0-9.]/gi, ''))
    if not isNaN(probablyCost)
      return name: str.substring(0, ci), cost: probablyCost
  name: str, cost: 0

parseSafe = (val) ->
  return undefined if val is undefined
  JSON.parse(val)

Storage =
  loadProjects: () ->
    parseSafe(localStorage?.projects) ? []

  loadBudget: ->
    parseSafe(localStorage?.budget) ? []

  saveProjects: (projects) ->
    console.log JSON.stringify(projects)
    localStorage.projects = JSON.stringify(projects) if localStorage

  saveBudget: (budget) ->
    localStorage.budget = JSON.stringify(budget) if localStorage

TasksService =
  project: {}
  budget: new Budget(250)
  projects: []

  load: ->
    @projects = Storage.loadProjects()
    @projects.forEach (p) -> p.tasks = p.tasks.map (t) -> new Task(t.title, t.cost, t.status)
    @setBudget Storage.loadBudget()
    ###
    @projects = [{
      id: 1,
      name: "Puzzle project",
      image: "/img/pic1.jpg",
      tasks: [
        task("Create puzzle control", 0, "completed"),
        task("Make project page", 200),
        task("Make projects list", 500),
        task("Update styles", 200),
      ]
    }]

    ###

  save: ->
    Storage.saveProjects(@projects)
    Storage.saveBudget(@budget.amount)

  _nextId: ->
    return 1 if @projects.length == 0
    1 + (Math.max.apply null, @projects.map (p) ->p.id)

  addProject: (name, image) ->
    proj = {name, image, tasks:[], id: @_nextId()}
    @projects.push proj
    @save()
    proj

  deleteProject: (project) ->
    @projects.splice @projects.indexOf(project), 1
    @save()

  getProject: (id) ->
    @projects.filter((p) ->p.id.toString() == id.toString())[0]

  selectProject: (project_or_id) ->
    project = if project_or_id.id then project_or_id else @getProject(project_or_id)
    for name, value of project
      @project[name] = value

  unselectProject: ->
    @project.id = null

  updateStatus: ->
    return if not @project.id
    @project.tasks.forEach (t)=>t.updateStatus(@budget)
    @save()

  addTask: (name, cost) ->
    return if not @project.id
    {name, cost} = parseString name, cost
    @_addTask task(name, cost).updateStatus(@budget)

  deleteTask: (task) ->
    return if not @project.id
    @project.tasks.splice @project.tasks.indexOf(task), 1

  _addTask: (task) ->
    @project.tasks.push task
    @save()
    task




  toggle: (task) ->
    if task.is "completed"
      task.revert @budget
    else if task.is "available"
      task.complete @budget
    else
      throw new Error "not.available"
    @updateStatus()


  setBudget: (newValue) ->
    @budget.set parseFloat(newValue)
    @updateStatus()
    @save()

  getProjectProgress: (project) ->
    completed = project.tasks.filter((t) -> t.is "completed").length
    total = project.tasks.length
    if total is 0 then 0 else 100*completed/total

module.exports = TasksService



