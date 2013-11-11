app = angular.module('puzzle', ['granula'])
(require './backend/parse_angular')(app)

safeApply = ($scope, cb = ->)->
  if not $scope.$root.$$phase
    $scope.$apply(cb)
  else
    cb()

{getDialog} = (require './ui')(app, safeApply)
(require './tasks/selection')(app)
(require './tasks/actions')(app)
(require './auth/auth')(app)
(require './model/tasks_angular')(app)

app.config ['budgetProvider', 'statusProvider', (budgetProvider, status) ->
  #budgetProvider.setMode 'debug'
  #budgetProvider.setMode 'local'
  budgetProvider.setErrorHandler (err) ->
    status.onError err
    console.error "ERR", err
]

app.controller 'global', ['$scope', 'budget', 'auth', '$location', 'status', ($scope, budget, auth, $location, status) ->
  $scope.loading = true
  reset = ->
    $scope.budget = {amount: 0}
    $scope.booking = {amount: ->undefined}
  reset()
  $scope.auth = auth
  $scope.$on 'auth:loggedIn', ->
    budget.load().then ((budget) ->
      $scope.budget = budget
      $scope.booking = budget.booked
      $scope.loading = false
      safeApply($scope)
    ), (error) ->
      console.error error if error
  $scope.$on 'auth:loginFailed', ->
    $location.path "/auth"
  $scope.logout = ->
    reset()
    budget.unload()
    auth.logout(->)
  auth.check()
  $scope.$on '$routeChangeSuccess', (ev, route) ->
    if $location.path() != '/auth' && not auth.loggedIn && not auth.checking
      $location.path "/auth"
    $scope.section = route.section

  $scope.import = ->
    b = $scope.budget
    b.set data.amount
    pByName = {}
    projectsToSave = data.projects.length
    for pData in data.projects
      project = b.addProject pData, ->
        projectsToSave--
        if projectsToSave == 0
          continueWithTasks()

      pByName[project.name] = project
    continueWithTasks = ->
      for tData in data.tasks
        project = pByName[tData.project]
        if project is undefined
          console.error "Cannot import task - unknown project '#{tData.project}' - #{JSON.stringify(tData, null, 4)}"
          continue
        task = project.addTask tData
]

app.controller 'footer', ['$scope', 'status', ($scope, status) ->
  $scope.ajaxStatus = status.status
  $scope.dialogs =
    error:
      show: false
    help:
      show: false
  $scope.hideErrors = ->
    status.hideErrors()
  $scope.clickInfo = ->
    if status.status.showError
      $scope.dialogs.error.show = true
    else
      $scope.dialogs.help.show = true

]

app.controller 'header', ['$scope', ($scope) ->
  $scope.$watch 'budget.amount', (newVal) ->
    return unless $scope.auth?.loggedIn
    $scope.budget.set newVal
  $scope.budgetInEdit = null
  #TODO: make service or directive for editing. pattern is simple
  # edit.start -> copy some props from real object to editable
  # edit.save -> copy back, call saving method, erase
  # edit.cancel -> erase
  $scope.editBudget = ->
    return $scope.cancelBudget() if $scope.budgetInEdit
    $scope.budgetInEdit = {
      amount: $scope.budget.amount,
      currency: $scope.budget.currency
    }
  $scope.saveBudget = ->
    $scope.budget.currency = $scope.budgetInEdit.currency
    $scope.budget.set($scope.budgetInEdit.amount)
    $scope.budgetInEdit = null
  $scope.cancelBudget = ->
    $scope.budgetInEdit = null
]

app.config ['$routeProvider', ($routeProvider) ->
  $routeProvider.when '/', controller: 'projects', templateUrl: './projects.html', section:'projects'
  $routeProvider.when '/reports/:year/:month', controller: 'reports', templateUrl: './reports.html', section:'reports'
  $routeProvider.when '/reports/:year', controller: 'reports', templateUrl: './reports.html', section:'reports'
  $routeProvider.when '/reports', controller: 'reports', templateUrl: './reports.html', section:'reports'
  $routeProvider.when '/auth', controller: 'login', templateUrl: './login.html'
  $routeProvider.when '/:project', controller: 'project', templateUrl: './project.html', section:'projects'
]

app.controller 'login', ['$scope', 'auth', '$location', ($scope, auth, $location) ->
  $scope.auth = auth
  if auth.loggedIn
    return $location.path "/"
  onLogReg = (user, error) ->
    $scope.logReg = false
    if user
      $location.path "/"
    else
      $scope.error = error
      error.isLogin = true
    safeApply($scope)
  startCall = ->
    $scope.error = null
    $scope.logReg = true
  $scope.register = ->
    startCall()
    auth.register $scope.auth.username, $scope.auth.password, {}, onLogReg
  $scope.login = ->
    startCall()
    auth.login $scope.auth.username, $scope.auth.password, onLogReg
]

app.controller 'projects', ['$scope', '$location', 'tasksSelection', ($scope, $location, tasksSelection) ->
  $scope.newProject = {title:""}
  $scope.addProject = ->
    if $scope.newProject.title
      $scope.budget.addProject {name: $scope.newProject.title}, (err, proj)->
        $scope.$apply ->
          $location.path "/#{proj.objectId}"
    $scope.$apply()
  $scope.deleteProject = (project) ->
    project.delete()
  $scope.isBooked = (task) ->
    $scope.booking.include(task)

  # selection
  $scope.selection = tasksSelection.createSelection()
  $scope.$on "$destroy", ->
    $scope.selection.deselectAll()
]

SHOW_COMPLETED_KEY = 'NIH_proj_show_completed'

app.controller 'project', ['tasksSelection', 'budget', '$scope', '$routeParams', '$location', (tasksSelection, budget, $scope, $routeParams, $location) ->

  $scope.showCompleted = localStorage?[SHOW_COMPLETED_KEY] == 'true'
  $scope.$watch 'showCompleted', ->
    localStorage?[SHOW_COMPLETED_KEY] = $scope.showCompleted

  projectId = $routeParams.project
  budget.whenLoad().then (budget) ->
    $scope.project = budget.getProject(projectId)
    if $scope.project == null
      $location.path '/'
      #TODO: show error
      return
    visibleTasks = if $scope.showCompleted then $scope.project.tasks else $scope.project.nonCompleted()
    if (visibleTasks.length == 0)
      $scope.addTaskDialog = true
    safeApply($scope)
  safeAmount = (amount) ->
    amount = parseInt(amount)
    amount = 1 if isNaN(amount) or amount < 1
    amount
  $scope.currentTask = {}
  resetNewTask = ->
    $scope.newTask = {title: "", cost1: 0, amount: 1}
  resetNewTask()
  $scope.addTask = ->
    $scope.newTask.amount = safeAmount($scope.newTask.amount)
    $scope.newTask.cost = $scope.newTask.cost1 * $scope.newTask.amount
    $scope.project.addTask($scope.newTask, -> safeApply($scope)) if $scope.newTask.title
    resetNewTask()
    setTimeout (->
      $scope.addTaskDialog = true
      $scope.$apply()
    ), 0
  $scope.deleteTask = (task) ->
    $scope.project.deleteTask task
  $scope.toggleTask = (task) ->
    task.toggle().then -> safeApply($scope)
  $scope.isBooked = (task) ->
    $scope.booking.include(task)
  $scope.toggleBookingTask = (task) ->
    $scope.booking.toggle(task)

  # editing
  $scope.taskInEdit = null
  $scope.editTask = (task) ->
    wasEdited = $scope.isInEdit(task)
    $scope.cancelEdit()
    return if wasEdited
    $scope.selection.deselectAll()
    $scope.addTaskDialog = false
    $scope.taskInEdit = {
      original: task,
      edited: $.extend {}, task
    }
    $scope.taskInEdit.edited.cost1 = $scope.taskInEdit.edited.cost / $scope.taskInEdit.edited.amount

  $scope.cancelEdit = ->
    $scope.taskInEdit = null
  $scope.saveTask = (task) ->
    task.withStatusUpdate (task) ->
      task.title = $scope.taskInEdit.edited.title
      task.amount = safeAmount($scope.taskInEdit.edited.amount)
      task.cost = $scope.taskInEdit.edited.cost1 * task.amount

    task.save()
    $scope.cancelEdit()
  $scope.isInEdit = (task) ->
    $scope.taskInEdit?.original is task

  # selection

  $scope.selection = tasksSelection.createSelection()
  $scope.$on "$destroy", ->
    $scope.selection.deselectAll()
]

app.controller 'reports', ['budget', '$scope', '$routeParams', '$location', (budget, $scope, $routeParams, $location) ->
  year = parseFloat($routeParams.year)
  month = parseFloat($routeParams.month)
  month = 0 if not isNaN(year) and isNaN(month)
  today = new Date()
  if isNaN(year) and isNaN(month)
    date = today
    year = date.getFullYear()
    month = date.getMonth()
  else if year > today.getFullYear() || month > today.getMonth()
    $location.path "/reports"
  else
    date = new Date()
    date.setFullYear(year)
    date.setMonth(month)

  $scope.loading = true
  $scope.month = month
  $scope.monthR = month
  $scope.year = year
  $scope.prev = {
    month: if month == 0 then 11 else month - 1
    year: if month == 0 then year - 1 else year
  }
  $scope.next = {
    month: if month == 11 then 0 else month + 1
    year: if month == 11 then year + 1 else year
  }
  $scope.hasNext = true
  $scope.loadReport = ->
    $scope.report = {loading: true}
    budget.whenLoad().then (budget) ->
      $scope.report = budget.report($scope.month, $scope.year, 2, 2)
      $scope.hasNext = (year < today.getFullYear() || month < today.getMonth())
      safeApply($scope)
  $scope.loadReport()

  #edit
  $scope.taskInEdit = {}
  $scope.isInEdit = (task) -> $scope.taskInEdit.task == task
  $scope.months = [0..11]
  $scope.years = [year-2..year+1]
  $scope.editTask = (task) ->
    return $scope.cancelEdit() if $scope.isInEdit(task)
    $scope.taskInEdit.task = task
    $scope.taskInEdit.edited = {cMonth: task.cMonth, cYear: task.cYear}

  $scope.cancelEdit = ->
    $scope.taskInEdit = {}
  $scope.saveTask = (task) ->
    task.cMonth = parseInt($scope.taskInEdit.edited.cMonth)
    task.cYear = parseInt($scope.taskInEdit.edited.cYear)
    return $scope.cancelEdit() if isNaN(task.cMonth) || isNaN(task.cYear)
    task.save({}, {now: true}).then ->
      $scope.loadReport()
    $scope.cancelEdit()
]

app.filter 'nonCompleted', ->
  (input, doFilter) ->
    return input if not doFilter or input is undefined or input is null
    input.filter (t) -> not t.is('completed')

app.service 'projectThumbModel', ->
  create: (project, maxAmountOfTasks) ->
    getTotal = (project) -> project.tasks.length
    calculateProgress = (project) ->
      total = getTotal(project)
      for status, title of {completed: "tasks completed", available: "tasks ready to be completed", unavailable: "tasks cannot be completed right now"}
        count = project[status]().length
        {
          percent: count / total * 100,
          amount: count,
          total: total,
          name: status,
          title: "of #{total} #{title}"
        }
    calculateTasksToShow = (project) ->
      availableTasks = project.available()
      unavailableTasks = project.unavailable()
      completedTasks = project.completed()
      total = availableTasks.length + unavailableTasks.length + completedTasks.length
      tasksToShow = availableTasks.slice().concat(unavailableTasks).slice(0, maxAmountOfTasks)
      if (tasksToShow.length < availableTasks.length + unavailableTasks.length)
        tasksToShow.pop()
        rest = total - maxAmountOfTasks + 1
        tasksToShow.push {rest: rest, status: "more", text: "..."}
      tasksToShow
    update: ->
      #@tasksToShow.splice.apply(@tasksToShow, [0, @tasksToShow.length].concat(calclateTasksToShow(project)))
      for prog, index in calculateProgress(project)
        @progressToShow[index] = prog
      #TODO: switch when all tasks completed
    tasksToShow: calculateTasksToShow(project)
    progressToShow: calculateProgress(project)




app.directive 'projectThumb', ['projectThumbModel', '$location', (projectThumbModel, $location) ->
  scope:
    project: "=projectThumb"
    selection: "=selection"
    deleteProject: "&deleteProject"
    isBooked: "&isBooked"
  replace: true
  templateUrl: "partial/project-thumb.html"
  link: (scope, el, attrs) ->
    scope.thumb = projectThumbModel.create(scope.project, attrs.thumbs ? 9, scope.thumb)
    scope.click = (task) ->
      if task.status == "more"
        $location.path "/#{scope.project.objectId}"
    scope.isSelected = (task) -> scope.selection.isSelected(task)
]

app.directive 'ngEnter', ->
  (scope, el, attrs) ->
    el.keydown (e) ->
      if e.which == 13
        scope.$apply ->
          scope.$eval attrs.ngEnter
