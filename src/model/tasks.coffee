this.require = false
if require
  ModelMixin = require('./persistence')
else
  ModelMixin = window.ModelMixin

class Group
  constructor: (@name, @budget) ->

  include: (task) -> task.groups.indexOf(@name) > -1
  tasks: -> @budget.tasks.filter (t) => t.completed == 0 and t.deleted == 0 and @include(t)
  amount: -> @tasks(@budget).map((t) ->t.cost).reduce(((a,b)->a+b), 0)

class Task extends ModelMixin
  @properties "title", "completed", "deleted", "cMonth", "cYear", "cProjectName", "project", "cost", "budget", "groups", "amount"
  constructor: (data = {}) ->
    Task.init(@)
    @load(data)
    @deleted = 0
    @completed = 0
    @afterLoad()
  afterLoad: (cb = ->) ->
    @cost = parseInt(@cost)
    @cost = 0 if isNaN(@cost)
    @groups ?= []
    @updateStatus()
    cb()
  withBudget: (cb)->
    if typeof @budget == 'object'
      cb(@budget)
  withStatusUpdate: (cb) ->
    cb(@)
    @updateStatus()
  updateStatus: ->
    if @completed == 1
      @status = 'completed'
    else
      @withBudget (b) =>
        @status = if b.isEnough(@) then 'available' else 'unavailable'
  toggle: ->
    if @completed == 1
      @uncomplete()
    else
      @complete()
  complete: ->
    return if @completed == 1
    @save {completed: 1}, {
      safe: true,
      success: =>
        comDate = new Date()
        @save {cMonth: comDate.getMonth(), cYear: comDate.getFullYear()}
        @withBudget (b)=> b.onComplete(@)
      error: (err) =>
        @updateStatus() if err.conflict
        #error
    }
  uncomplete: ->
    return if @completed == 0
    @save {completed: 0}, {
      safe: true,
      success: =>
        @withBudget (b) => b.onUncomplete(@)
      error: (err) =>
        @updateStatus() if err.conflict

    }
  delete: ->
    @save {deleted: 1}, {
      safe: true
    }
BOOKED = "booked"

class Budget extends ModelMixin
  @properties "amount", "owner"
  constructor: ({@amount} = {})->
    Budget.init(@)
    @tasks = []
    @booked = new Group(BOOKED, @)
    @owner = "@currentUser"

  linkRelation: (fieldName) ->
    (obj) =>
      obj[fieldName] = (act) => act(@)

  afterLoad: (cb) ->
    Task.find({budget: @objectId, deleted: 0}, {
      success: (tasks) =>
        tasks.forEach (t) =>
          t.budget = @
          t.updateStatus()
        @tasks = tasks

      error: =>
        #error
    }).then =>
      Project.find({budget: @objectId, deleted: 0}, {
        success: (projects) =>
          projects.forEach (p) => p.budget = @
          @projects = projects
          @_linkProjectsTasks()
          cb()
      })

  _linkProjectsTasks: ->
    pid = {}
    @projects.forEach (p) -> pid[p.objectId] = p
    @tasks = @tasks.filter (t) =>
      if not t.project
        console.error "Task does not have link to project, so it will be ignored"
        return false
      if not pid[t.project]
        console.error "Project with id = #{t.project} does not belong to this budget"
        return false
      project = pid[t.project]
      t.project = project
      project.attachTask(t)
      true

  isEnough: (task) ->
    task.cost <= @amount

  report: (month, year) ->
    report = {loading:true, tasks: []}
    Task.find {budget: @objectId, completed: 1, cMonth:month, cYear: year}, {
      success: (tasks) ->
        report.loading = false
        report.tasks = tasks
      error: ->
        #error
    }
    report

  set: (amount) ->
    newAmount = parseInt(amount)
    return if @amount == newAmount
    @save {amount: newAmount}
    @updateStatuses()

  onComplete: (task) ->
    @set @amount - task.cost

  onUncomplete: (task) ->
    @set @amount + task.cost

  updateStatuses: (container = @) ->
    container.tasks.forEach (t) =>t.updateStatus()

  addProject: (props, cb = ->) ->
    props.budget = @
    project = new Project(props)
    project.save().then ((project) =>
      project.budget = @
      @projects.push(project)
      cb(null, project)
    ), (err) -> cb(err)

  deleteProject: (proj) ->
    @projects.splice @projects.indexOf(proj), 1

  addTask: (props, cb = ->) ->
    props.budget = @
    task = new Task(props)
    task.save().then ((task) =>
      @linkRelation("withBudget")(task)
      @tasks.push(task)
      @updateStatuses(props.updateStatusesFor)
      cb(null, task)
    ), (err) ->
      cb(err)

  @load: (cb) ->
    Budget.find {owner: "@currentUser"}, {
      success: (budgets) ->
        if budgets.length > 0
          cb(null, budgets[0])
        else
          new Budget(amount: 0).save().then ((b) -> cb(null, b)), (err) -> cb(err)
      error: (_, e) -> cb(e)}

class Project extends ModelMixin
  @PARSE_CLASS = "Project2"
  @properties "name", "deleted", "budget"
  constructor: ({@name, @budget} = {}) ->
    Project.init(@)
    @deleted = 0
    @tasks = []
  attachTask: (task) ->
    @tasks.push task
  nonDeleted: ->
    @tasks.filter (t) -> !t.deleted
  completed: ->
    @tasks.filter (t) ->t.status == 'completed'
  nonCompleted: ->
    @tasks.filter (t) ->t.status != 'completed'
  available: ->
    @tasks.filter (t) ->t.status == 'available'
  unavailable: ->
    @tasks.filter (t) ->t.status == 'unavailable'
  addTask: (props, cb) ->
    props.project = @
    @budget.addTask props, cb
  deleteTask: (task) ->
    p = task.delete()
    @tasks.splice(@tasks.indexOf(task), 1)
    p
  delete: ->
    p = @save {deleted: 1}, {safe: true}
    @budget.deleteProject @
    p

ModelMixin.parseMixin {Task, Budget, Project}

if require
  module.exports = {Budget, remix: (mixin) -> mixin {Task, Budget, Project}}
else
  window.Budget = Budget
  window.Task = Task
  window.Project = Project
