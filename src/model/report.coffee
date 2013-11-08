find = (projects, name) ->
  (projects.filter (p) -> p.name == (name.name ? name))[0]

class Report
  constructor: () ->
    @_projects = []
    @_dates = []

  prependTasks: (month, year, tasks) ->
    @addTasks_(month, year, tasks, 'unshift')
  addTasks: (month, year, tasks) ->
    @addTasks_(month, year, tasks, 'push')
  addTasks_: (month, year, tasks, method) ->
    date = {month, year}
    date.projects = []
    for task in tasks
      project = find(date.projects, task.cProjectName)
      if not project
        project = {name: task.cProjectName}
        date.projects.push project
      project.tasks ?= []
      project.sum ?= 0
      project.tasks.push task
      project.sum += task.cost
    @_dates[method](date)
    for proj in date.projects
      if not find(@_projects, proj)
        @_projects.push {name: proj.name}
    @

  build: (month, year) ->
    report = {
      dates: @_dates,
      projects: @_projects,
      tasks: []
    }
    for project in @_dates.filter((d)->d.month == month && d.year == year)[0]?.projects ? []
      report.tasks = report.tasks.concat(project.tasks)
    for project in report.projects
      project.sums = []
      for date in report.dates
        project.sums.push (find(date.projects, project)?.sum)
    report


this.require = false
if require
  module.exports = Report
else
  window.Report = Report