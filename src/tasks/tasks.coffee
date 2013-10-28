
toFloat = (something) ->
  fl = parseFloat(something)
  fl = 0 if isNaN(fl)
  fl


class Budget
  constructor: (@amount) ->
  set: (@amount) ->
    @amount = toFloat(@amount)
  increase: (delta) -> @set @amount + toFloat(delta)
  decrease: (delta) -> @set @amount - toFloat(delta)

  isEnoughFor: (money) ->
    money <= @amount

class Group
  constructor: (@id, @name, @tasks = []) ->
    @amount = 0
    @_recalculate()

  #TODO: tasks shall have unique id as well
  _contains: (task) ->
    @tasks.indexOf(task) > -1
    #@tasks.some (t) ->t.id == task.id

  _listedIn: (task) ->
    task.groups.indexOf(@name) > -1

  _recalculate: ->
    @amount = (@tasks.map((t) -> t.cost).reduce ((a,b)->a+b), 0) ? 0

  #assumed that task is already linked to group and its cost is in amount
  #TODO: probably it is better to recalculate amount? as we reiterate all tasks anyway
  linkTask: (task) ->
    @tasks.push(task)

  onTaskGroupChange: (task) ->
    if @_listedIn(task)
      if not @_contains(task)
        @tasks.push(task)
        @amount += toFloat(task.cost)
    else
      if @_contains(task)
        @tasks = @tasks.filter (t) ->t != task
        @amount -= toFloat(task.cost)

  onTaskCostChange: (task, oldCost, newCost) ->
    return if not @_listedIn(task)
    @amount = @amount - toFloat(oldCost) + toFloat(newCost)

  onTaskStatusChange: (task, oldStatus, newStatus) ->
    return if not @_listedIn(task)
    if newStatus == "completed"
      @amount -= toFloat(task.cost)
    else if oldStatus == "completed"
      @amount += toFloat(task.cost)

  serialize: ->
    {objectId: @id, @name, @amount}

  deserialize: (groupData)->
    @id = groupData.objectId
    @name = groupData.name
    @amount = groupData.amount

class EventEmitter
  constructor: ->
  trigger: (eventName, args...)->
    $(@).trigger(eventName, args)
  on: (eventName, listener) ->
    $(@).on eventName, (event, args...) ->
      listener(args...)
  off: (eventName, listener) ->
    $(@).off(eventName, listener)

TaskEvent =
  StatusChange: "task_status_change"
  CostChange: "task_cost_change"
  GroupChange: "task_groups_change"

class Task extends EventEmitter
  constructor: (@title, @cost = 0, @status = "", @groups = []) ->
    super
    @cost = toFloat(@cost)

  complete: (budget) ->
    return if @status is "completed"
    throw new Error("Task '#{@title}' cannot be done") if @status is not "available"
    @_change "status", "completed"
    budget.decrease @cost

  _change: (field, newVal) ->
    oldVal = @[field]
    return if oldVal == newVal
    @[field] = newVal
    @trigger "task_#{field}_change", oldVal, newVal

  updateCost: (newCost) ->
    @_change "cost", newCost

  addToGroup: (groupName) ->
    @_change "groups", @groups.concat([groupName])

  removeFromGroup: (groupName) ->
    @_change "groups", @groups.filter (g) ->g != groupName

  isInGroup: (groupName) ->
    @groups.indexOf(groupName) > -1

  updateStatus: (budget) ->
    oldStatus = @status
    return false if @status is "completed"
    #TODO: introduce consts for statuses
    @_change "status", if budget.isEnoughFor(@cost) then "available" else "unavailable"
    @status != oldStatus

  revert: (budget) ->
    throw new Error("Task '#{@title}' cannot be undone - it is not completed") if @status is not "completed"
    @_change "status", ""
    budget.increase @cost
    @updateStatus budget

  is: (status) -> @status == status

  toJSON: ->


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

class Project
  byStatus: (status) -> @tasks.filter (t) -> t.is(status)
  completed: -> @byStatus("completed")
  available: -> @byStatus("available")
  unavailable: -> @byStatus("unavailable")
  toJSON: ->
    newObj = angular.copy(@)
    for own key, val of newObj
      delete newObj[key] if $.isFunction(val)
    newObj.tasks = @tasks.map (t) ->t.toJSON()
    newObj

isInternal = (prop) ->
  prop.indexOf('_eventObj_') == 0

copyProperties = (obj) ->
  if angular.isArray(obj)
    return obj.map (item) -> copyProperties(item)
  else if angular.isObject(obj)
    newObj = {}
    for own key, val of obj
      newObj[key] = copyProperties(val) unless $.isFunction(val) or isInternal(key)
    newObj
  else
    return obj


toJSON = (obj) ->
  #return obj.toJSON() if obj.toJSON
  copyProperties(obj)



TasksService = (storage = require('./localStorage')) ->

  addTask = (service, args...) ->
    task = new Task(args...)
    task.on TaskEvent.StatusChange, (oldStatus, newStatus) -> service.onTaskStatusChange task, oldStatus, newStatus
    task.on TaskEvent.CostChange, (oldCost, newCost) -> service.onTaskCostChange task, oldCost, newCost
    task.on TaskEvent.GroupChange, () -> service.onTaskGroupChange task
    task

  BOOKED = "booked"

  project: {}
  budget: new Budget(0)
  projects: []
  options: {}
  loading: true
  booking: new Group(null, BOOKED)

  onTaskStatusChange: (task, oldStatus, newStatus) ->
    @booking.onTaskStatusChange task, oldStatus, newStatus
    storage.saveGroup @booking.serialize()

  onTaskCostChange: (task, oldCost, newCost) ->
    @booking.onTaskCostChange task, oldCost, newCost
    storage.saveGroup @booking.serialize()

  onTaskGroupChange: (task) ->
    @booking.onTaskGroupChange(task)
    storage.saveGroup @booking.serialize()

  load: (cb) ->
    clear @project, @projects, @options
    @loading = true
    @_loadGroups =>
      storage.getProjects (projects, error) =>
        return cb(error) if error
        projects.forEach (p) =>
          proj = new Project()
          angular.copy(p, proj)
          proj.tasks = proj.tasks.map (t) => addTask(@, t.title, t.cost, t.status, t.groups)
          @_linkTasksAndGroups proj.tasks
          @projects.push proj
        @booking._recalculate() #TODO: decide - recalculate or store
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

  _loadGroups: (cb) ->
    storage.getGroup BOOKED, (err, group) =>
      next = (err, group) =>
        @booking.deserialize(group)
        cb()
      if err == storage.GROUP_NOT_FOUND
        storage.addGroup {name: BOOKED, amount: 0}, next
      else
        next(null, group)

  _linkTasksAndGroups: (tasks) ->
    groups = [@booking]
    for task in tasks
      for group in groups
        if (task.isInGroup(group.name))
          group.linkTask(task)

  setCurrency: (c, cb = ->) ->
    @options.currency = c
    storage.setOptions @options, cb

  _nextId: ->
    return 1 if @projects.length == 0
    1 + (Math.max.apply null, @projects.map (p) ->p.id)

  addProject: (name, image, cb = ->) ->
    proj = {name, image, tasks:[]}
    storage.addProject proj, (project) =>
      @projects.push new Project(project)
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
    @_updateProjectStatus(@project)

  _updateAllProjectStatuses: (forceForTask = null)->
    @projects.forEach (p) => @_updateProjectStatus(p, forceForTask)

  _updateProjectStatus: (project, forceForTask = null) ->
    updated = false
    project.tasks.forEach (t) =>
      if t.updateStatus(@budget)
        updated = true

    if updated || project.tasks.indexOf(forceForTask) != -1
      @_saveProject(project)

  _saveProject: (project) ->
    console.log "Save project #{project.name}"
    storage.saveProject toJSON(project) if project.objectId

  _saveCurrentProject: ->
    storage.saveProject toJSON(@project) if @project.objectId

  addTask: (name, cost) ->
    return if not @project.objectId
    {name, cost} = parseString name, cost
    t = addTask(@, name, cost)
    t.updateStatus(@budget)
    @_addTask t

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

  toggleBooking: (task) ->
    if (task.isInGroup(BOOKED)) then task.removeFromGroup(BOOKED) else task.addToGroup(BOOKED)
    storage.saveGroup @booking.serialize()
    @_saveCurrentProject()

  isBooked: (task) ->
    task.isInGroup(BOOKED)

  toggle: (task) ->
    if task.is "completed"
      task.revert @budget
    else if task.is "available"
      task.complete @budget
    else
      throw new Error "not.available"
    @_updateAllProjectStatuses(task)
    #TODO: другие проекты тоже надо обновить. но хорошо бы избежать лишних сохранений


  setBudget: (newValue) ->
    @budget.set parseFloat(newValue)
    @_updateAllProjectStatuses()
    storage.setBudget @budget

  getProjectProgress: (project) ->
    completed = project.tasks.filter((t) -> t.is "completed").length
    total = project.tasks.length
    if total is 0 then 0 else 100*completed/total

  getBooking: -> @booking

  getStatusForCost: (cost) ->
    if @budget.isEnoughFor(cost) then "available" else "unavailable"


module.exports = TasksService



