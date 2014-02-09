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
      tasks: [],
      currentDateIdx: 0
    }
    curDate = @_dates.filter((d)->d.month == month && d.year == year)[0]
    report.currentDateIdx = @_dates.indexOf(curDate)
    for project in curDate?.projects ? []
      report.tasks = report.tasks.concat(project.tasks)
    for project in report.projects
      project.sums = []
      project.tooltips = []
      for date in report.dates
        projectData = find(date.projects, project)
        project.sums.push (projectData?.sum)
        project.tooltips.push projectData?.tasks.map((t) -> {title: t.title, cost: t.cost})
    report


this.require = false
if require
  module.exports = Report
else
  window.Report = Report

window.dateUtils =
  nextMonth: (d, count = 1) ->
    res = {month:d.month, year:d.year}
    for i in [1..count]
      res.month++
      if res.month >= 12
        res.month = 0
        res.year++
    res
  prevMonth: (d, count = 1) ->
    res = {month:d.month, year:d.year}
    for i in [1..count]
      res.month--
      if res.month < 0
        res.month = 11
        res.year--
    res