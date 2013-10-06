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
(require './auth/auth')(app)

app.controller 'global', ($scope, tasksService, backend, auth, $location) ->
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

app.controller 'projects', (tasksService, $scope, $location) ->
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



app.controller 'project', (tasksService, $scope, $routeParams) ->

  $scope.actionTitle =
    available: "Upgrade"
    completed: "Downgrade"
    unavailable: "Locked"

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


  # editing
  $scope.taskInEdit = null
  $scope.editTask = (task) ->
    wasEdited = $scope.isInEdit(task)
    $scope.cancelEdit()
    return if wasEdited
    $scope.taskInEdit = {
      original: task,
      edited: $.extend {}, task
    }

  $scope.cancelEdit = ->
    $scope.taskInEdit = null
  $scope.saveTask = (task) ->
    task.title = $scope.taskInEdit.edited.title
    task.cost = $scope.taskInEdit.edited.cost
    tasksService.saveTask(task)
    $scope.cancelEdit()
  $scope.isInEdit = (task) ->
    $scope.taskInEdit?.original is task



app.directive 'projectThumb', (tasksService) ->
  scope:
    project: "=projectThumb"
  template:
    """
    <div class="project">
      <a href="#/{{ project.objectId }}">{{ project.name }} - {{ progress(project).toFixed(0) }} %</a>
    </div>
    """
  link: (scope, el, attrs) ->
    scope.progress = tasksService.getProjectProgress


app.directive 'ngEnter', ->
  (scope, el, attrs) ->
    el.keydown (e) ->
      if e.which == 13
        scope.$apply ->
          scope.$eval attrs.ngEnter

app.directive 'editTask', ->
  (scope, el, attrs) ->