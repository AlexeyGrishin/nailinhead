tasksService = require './tasks/tasks'

app = angular.module('puzzle', [])
app.service 'tasksService', ->
  tasksService.load()
  tasksService

require './test'
{getDialog} = (require './ui')(app)

app.controller 'global', ($scope, tasksService) ->
  $scope.currency = tasksService.options.currency

app.controller 'header', ($scope, tasksService) ->
  $scope.budget = tasksService.budget
  $scope.$watch 'currency', (newVal) ->
    tasksService.setCurrency(newVal) if newVal
  $scope.$watch 'budget.amount', (newVal) ->
    tasksService.setBudget newVal

app.config ($routeProvider) ->
  $routeProvider.when '/', controller: 'projects', templateUrl: './projects.html'
  $routeProvider.when '/:project', controller: 'project', templateUrl: './project.html'

app.controller 'projects', (tasksService, $scope, $location) ->
  $scope.projects = tasksService.projects
  $scope.newProject = {title:""}
  $scope.addProject = ->
    if $scope.newProject.title
      proj = tasksService.addProject $scope.newProject.title, "/img/pic1.jpg"
      $location.path "/#{proj.id}"
    $scope.$apply()
  $scope.deleteProject = (project) ->
    tasksService.deleteProject project



app.controller 'project', (tasksService, $scope, $routeParams) ->

  $scope.actionTitle =
    available: "Upgrade"
    completed: "Downgrade"
    unavailable: "Locked"

  projectId = $routeParams.project
  tasksService.selectProject(projectId)
  tasksService.updateStatus()
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

  $scope.project = tasksService.project
  if ($scope.project.tasks.length == 0)
    $scope.addTaskDialog = true

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
      <a href="#/{{ project.id }}">{{ project.name }} - {{ progress(project).toFixed(0) }} %</a>
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