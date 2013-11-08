this.require = false
if require
  ModelMixin = require('./persistence')
  Report = require('./report')
else
  ModelMixin = window.ModelMixin
  Report = window.Report


copy = (props) ->
  o = {}
  for own key,val of props
    o[key] = val
  o

class Group
  constructor: (@name, @budget) ->

  include: (task) -> task.groups? && task.groups.indexOf(@name) > -1
  tasks: -> @budget.tasks.filter (t) => t.completed == 0 and t.deleted == 0 and @include(t)
  amount: -> @tasks(@budget).map((t) ->t.cost).reduce(((a,b)->a+b), 0)
  toggle: (task) ->
    if @include(task)
      task.groups.splice(task.groups.indexOf(@name), 1)
    else
      task.groups.push(@name)
    task.save()

class Task extends ModelMixin
  @properties "title", "completed", "deleted", "cMonth", "cYear", "cProjectName", "project", "cost", "budget", "groups", "amount"
  constructor: (data = {}) ->
    Task.init(@)
    @load(data)
    @deleted = 0
    @completed = 0
    @afterLoad()
  _checkCost: ->
    @cost = parseInt(@cost)
    @cost = 0 if isNaN(@cost)
    @amount = parseInt(@amount)
    @amount = 1 if isNaN(@amount) or @amount < 1
  afterLoad: (cb = ->) ->
    @_checkCost()
    @amount ?= 1
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
    @_checkCost()
    if @completed == 1
      @status = 'completed'
    else
      @withBudget (b) =>
        @status = b.getStatusForCost(@cost)
  toggle: ->
    if @completed == 1
      @uncomplete()
    else
      @complete()
  is: (status) -> status == @status
  complete: ->
    return if @completed == 1
    p = new Parse.Promise()
    @withBudget (b)=> b.onComplete(@)
    @save {completed: 1}, {
      safe: true,
      success: =>
        comDate = new Date()
        @save {cMonth: comDate.getMonth(), cYear: comDate.getFullYear(), cProjectName: @project.name}
      error: (err) =>
        if err.conflict
          @withBudget (b)=> b.onUncomplete(@)
        #error
    }
    @updateStatus()
    p
  uncomplete: ->
    return if @completed == 0
    @withBudget (b) => b.onUncomplete(@)
    p = @save {completed: 0}, {
      safe: true,
      success: =>
        #that's ok
      error: (err) =>
        @withBudget (b) => b.onComplete(@) if err.conflict
    }
    @updateStatus()
    p
  delete: ->
    @save {deleted: 1}, {
      safe: true
    }
BOOKED = "booked"

class Budget extends ModelMixin
  @properties "amount", "owner", "currency"
  constructor: ({@amount} = {})->
    Budget.init(@)
    @tasks = []
    @booked = new Group(BOOKED, @)
    @owner = "@currentUser"

  linkRelation: (fieldName) ->
    (obj) =>
      obj[fieldName] = (act) => act(@)

  afterLoad: (cb) ->
    @currency ?= 'RUR'
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

  getStatusForCost: (cost) ->
    if @isEnough({cost}) then 'available' else 'unavailable'


  report: (month, year) ->
    report = {loading:true}
    getTasks = (month, year, reportBuilder, prevMonth, cb) =>
      Task.find(budget: @objectId, completed: 1, cMonth:month, cYear: year).then (tasks) ->
        reportBuilder.prependTasks(month, year, tasks)
        if prevMonth > 0
          month--
          if month < 0
            month = 11
            year--
          getTasks(month, year, reportBuilder, prevMonth-1, cb)
        else
          cb(reportBuilder)
      , (error) -> #error
    builder = new Report()
    getTasks month, year, builder, 2, ->
      r = builder.build(month, year)
      report.tasks = r.tasks
      report.dates = r.dates
      report.projects = r.projects
      report.loading = false
    report

  set: (amount, force = false) ->
    newAmount = parseInt(amount)
    if @amount is undefined
      @amount = amount
    return if @amount == newAmount
    @save {amount: newAmount}, {now: force}
    @updateStatuses()

  onComplete: (task) ->
    @set @amount - task.cost

  onUncomplete: (task) ->
    @set @amount + task.cost

  updateStatuses: (container = @) ->
    container.tasks.forEach (t) =>t.updateStatus()

  addProject: (props, cb = ->) ->
    props = copy(props)
    props.budget = @
    project = new Project(props)
    project.save().then ((project) =>
      project.budget = @
      @projects.push(project)
      cb(null, project)
    ), (err) -> cb(err)
    project

  getProject: (id) -> @projects.filter((p) -> p.objectId == id)[0] ? null

  deleteProject: (proj) ->
    @projects.splice @projects.indexOf(proj), 1

  addTask: (props, cb = ->) ->
    props = copy(props)
    props.budget = @
    task = new Task(props)
    @tasks.push(task)
    task.project.tasks.push(task)
    task.save().then ((task) =>
      @linkRelation("withBudget")(task)
      @updateStatuses(props.updateStatusesFor)
      cb(null, task)
    ), (err) ->
      cb(err)
    task

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
    props = copy(props)
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
