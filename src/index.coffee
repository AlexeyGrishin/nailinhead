createTasksService = require './tasks/tasks'

app = angular.module('puzzle', [])
localStorage = require './tasks/localStorage'
(require './backend/parse_angular')(app)
app.service 'tasksService', (backend) ->
  tasksService = createTasksService backend
  backend.init()
  tasksService

require './test'
{getDialog} = (require './ui')(app)
(require './async')(app)
(require './tasks/selection')(app)
(require './tasks/actions')(app)
(require './auth/auth')(app)

app.controller 'global', ($scope, tasksService, backend, auth, $location) ->
  $scope.loading = true
  tasksService.onLoad ->
    $scope.loading = false
  $scope.options = tasksService.options
  $scope.auth = auth
  $scope.$on 'auth:loggedIn', ->
    console.log "load tasks"
    tasksService.load (error) ->
      console.error error if error
      $scope.$apply()
  $scope.$on 'auth:loginFailed', ->
    $location.path "/auth"
  $scope.logout = ->
    auth.logout(->)
  auth.check()

app.controller 'header', ($scope, tasksService) ->
  $scope.budget = tasksService.budget
  $scope.booking = tasksService.booking
  $scope.$watch 'currency', (newVal) ->
    return unless $scope.auth.loggedIn
    tasksService.setCurrency(newVal) if newVal
  $scope.$watch 'budget.amount', (newVal) ->
    return unless $scope.auth.loggedIn
    tasksService.setBudget newVal

app.config ($routeProvider) ->
  $routeProvider.when '/', controller: 'projects', templateUrl: './projects.html'
  $routeProvider.when '/auth', controller: 'login', templateUrl: './login.html'
  $routeProvider.when '/:project', controller: 'project', templateUrl: './project.html'

app.controller 'login', ($scope, auth, $location) ->
  $scope.auth = auth

  onLogReg = (user, error) ->
    if user
      $location.path "/"
    else
      $scope.error = error
    $scope.$apply()
  $scope.register = ->
    auth.register $scope.auth.username, $scope.auth.password, {
      options: {currency: "RUR"}
      budget: {amount: 10000}
    }, onLogReg
  $scope.login = ->
    auth.login $scope.auth.username, $scope.auth.password, onLogReg

app.controller 'projects', (tasksService, tasksSelection, $scope, $location) ->
  $scope.projects = tasksService.projects

  $scope.newProject = {title:""}
  $scope.addProject = ->
    if $scope.newProject.title
      tasksService.addProject $scope.newProject.title, "/img/pic1.jpg", (proj) ->
        $scope.$apply ->
          $location.path "/#{proj.objectId}"
    $scope.$apply()
  $scope.deleteProject = (project) ->
    tasksService.deleteProject project, ->
      $scope.$apply()

  # selection
  $scope.selection = tasksSelection.createSelection()
  $scope.$on "$destroy", ->
    $scope.selection.deselectAll()

app.controller 'project', (tasksSelection, tasksService, $scope, $routeParams) ->

  projectId = $routeParams.project
  tasksService.onLoad ->
    tasksService.selectProject(projectId)
    tasksService.updateStatus()
    $scope.project = tasksService.project
    if ($scope.project.tasks.length == 0)
      $scope.addTaskDialog = true
    $scope.$apply() if not $scope.$$phase

  $scope.currentTask = {}
  $scope.newTask = {title: ""}
  $scope.addTask = ->
    tasksService.addTask $scope.newTask.title, $scope.newTask.cost if $scope.newTask.title
    setTimeout (->
      $scope.addTaskDialog = true
      $scope.$apply()
    ), 0
  $scope.deleteTask = (task) ->
    tasksService.deleteTask task
  $scope.toggleTask = (task) ->
    tasksService.toggle(task)
  $scope.isBooked = (task) ->
    tasksService.isBooked(task)
  $scope.toggleBookingTask = (task) ->
    tasksService.toggleBooking(task)

  # editing
  $scope.taskInEdit = null
  $scope.editTask = (task) ->
    wasEdited = $scope.isInEdit(task)
    $scope.cancelEdit()
    return if wasEdited
    $scope.selection.deselectAll()
    $scope.taskInEdit = {
      original: task,
      edited: $.extend {}, task
    }

  $scope.cancelEdit = ->
    $scope.taskInEdit = null
  $scope.saveTask = (task) ->
    task.title = $scope.taskInEdit.edited.title
    task.updateCost($scope.taskInEdit.edited.cost)
    tasksService.saveTask(task)
    $scope.cancelEdit()
  $scope.isInEdit = (task) ->
    $scope.taskInEdit?.original is task

  # selection

  $scope.selection = tasksSelection.createSelection()
  $scope.$on "$destroy", ->
    $scope.selection.deselectAll()



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
        tasksToShow.push {title: "Show the rest #{rest} tasks", status: "more", text: "..."}
      tasksToShow
    update: ->
      #@tasksToShow.splice.apply(@tasksToShow, [0, @tasksToShow.length].concat(calclateTasksToShow(project)))
      for prog, index in calculateProgress(project)
        @progressToShow[index] = prog
      #TODO: switch when all tasks completed
    tasksToShow: calculateTasksToShow(project)
    progressToShow: calculateProgress(project)




app.directive 'projectThumb', (tasksService, projectThumbModel, $location) ->
  scope:
    project: "=projectThumb"
    selection: "=selection"
  replace: true
  templateUrl: "partial/project-thumb.html"
  link: (scope, el, attrs) ->
    scope.thumb = projectThumbModel.create(scope.project, attrs.thumbs ? 9, scope.thumb)
    scope.click = (task) ->
      if task.status == "more"
        $location.path "/#{scope.project.objectId}"
      else
        scope.selection.toggleSelection(task)
    scope.isBooked = (task) -> tasksService.isBooked(task) if task.status != 'more'
    scope.isSelected = (task) -> scope.selection.isSelected(task)
    scope.$watch("project", (-> scope.thumb.update()), true)

app.directive 'ngEnter', ->
  (scope, el, attrs) ->
    el.keydown (e) ->
      if e.which == 13
        scope.$apply ->
          scope.$eval attrs.ngEnter

