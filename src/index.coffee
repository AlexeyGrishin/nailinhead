tasksService = require './tasks/tasks'

app = angular.module('puzzle', [])
app.service 'tasksService', ->
  tasksService.load()
  tasksService

require './test'
(require './ui')(app)

app.controller 'header', ($scope, tasksService) ->
  $scope.budget = tasksService.budget
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
  projectId = $routeParams.project
  tasksService.selectProject(projectId)
  tasksService.updateStatus()
  $scope.currentTask = {}
  $scope.newTask = {title: ""}
  $scope.addTask = ->
    tasksService.addTask $scope.newTask.title if $scope.newTask.title
    $scope.dialog('addTaskDialog').show()
  $scope.deleteTask = (task) ->
    tasksService.deleteTask task
    $scope.$apply()
  $scope.project = tasksService.project
  $scope.toggleTask = (task) ->
    tasksService.toggle(task)



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

