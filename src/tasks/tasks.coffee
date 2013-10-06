
class Budget
  constructor: (@amount) ->
  set: (@amount) ->
    @amount = parseFloat(@amount)
    @amount = 0 if isNaN(@amount)
  increase: (delta) -> @set @amount + parseFloat(delta)
  decrease: (delta) -> @set @amount - parseFloat(delta)

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
  return {name:str, cost:cost} if cost
  if str.indexOf(',') != -1 or str.indexOf(' ') != -1
    ci = Math.max str.lastIndexOf(','), str.lastIndexOf(' ')

    probablyCost = parseFloat(str.substring(ci+1).replace(/[^0-9.]/gi, ''))
    if not isNaN(probablyCost)
      return name: str.substring(0, ci), cost: probablyCost
  name: str, cost: 0

clear = (objs...) ->
  for obj in objs
    if obj.splice
      obj.splice(0, obj.length)
    else
      angular.copy {}, obj

TasksService = (storage = require('./localStorage')) ->

  project: {}
  budget: new Budget(0)
  projects: []
  options: {}
  loading: true

  load: (cb) ->
    clear @project, @projects, @options
    @loading = true
    storage.getProjects (projects, error) =>
      return cb(error) if error
      projects.forEach (p) =>
        p.tasks = p.tasks.map (t) -> new Task(t.title, t.cost, t.status)
        @projects.push p
      storage.getBudget (budget, error) =>
        return cb(error) if error
        @setBudget(budget?.amount)
        storage.getOptions (options, error) =>
          angular.copy options, @options if options
          return cb(error) if error
          storage.saveCurrentUser()
          @loading = false
          $(@).trigger "tasks.loaded"
          cb()

  setCurrency: (c, cb = ->) ->
    @options.currency = c
    storage.setOptions @options, cb

  _nextId: ->
    return 1 if @projects.length == 0
    1 + (Math.max.apply null, @projects.map (p) ->p.id)

  addProject: (name, image, cb = ->) ->
    proj = {name, image, tasks:[]}
    storage.addProject proj, (project) =>
      @projects.push project
      cb(project)

  deleteProject: (project, cb = ->) ->
    storage.deleteProject project, =>
      @projects.splice @projects.indexOf(project), 1
      cb()

  getProject: (id) ->
    @projects.filter((p) ->p.objectId.toString() == id.toString())[0]

  onLoad: (cb) ->
    if @loading
      $(@).on 'tasks.loaded', cb
    else
      cb()

  selectProject: (project_or_id, cb) ->
    project = if project_or_id.objectId then project_or_id else @getProject(project_or_id)
    for name, value of project
      @project[name] = value

  unselectProject: ->
    @project.objectId = null

  updateStatus: ->
    return if not @project.objectId
    @project.tasks.forEach (t)=>t.updateStatus(@budget)
    @_saveCurrentProject()

  _saveCurrentProject: ->
    storage.saveProject angular.copy(@project) if @project.objectId

  addTask: (name, cost) ->
    return if not @project.objectId
    {name, cost} = parseString name, cost
    @_addTask task(name, cost).updateStatus(@budget)

  deleteTask: (task) ->
    return if not @project.objectId
    @project.tasks.splice @project.tasks.indexOf(task), 1
    @_saveCurrentProject()

  _addTask: (task) ->
    @project.tasks.push task
    @_saveCurrentProject()
    task


  saveTask: (task) ->
    @_saveCurrentProject()

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
    storage.setBudget @budget

  getProjectProgress: (project) ->
    completed = project.tasks.filter((t) -> t.is "completed").length
    total = project.tasks.length
    if total is 0 then 0 else 100*completed/total

module.exports = TasksService



