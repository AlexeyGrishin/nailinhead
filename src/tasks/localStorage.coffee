parseSafe = (val) ->
  return undefined if val is undefined
  JSON.parse(val)

Storage =
  getProjects: (cb) ->
    cb(parseSafe(localStorage?.projects) ? [])

  getBudget: (cb) ->
    cb(parseSafe(localStorage?.budget) ? {})

  getOptions: (cb) ->
    cb(parseSafe(localStorage?.options) ? {})

  setOptions: (options, cb = ->) ->
    localStorage.options = JSON.stringify(options) if localStorage
    cb()

  addProject: (project, cb = ->) ->
    @getProjects (projects) =>
      projects.push(project)
      @_saveProjects projects, ->
        cb(project)

  _findByID: (projects, id) ->
    projects.filter((p) ->p.id == id)[0]

  deleteProject: (project, cb = ->) ->
    @getProjects (projects) =>
      projects.splice(@_findByID(projects, project.id), 1)
      @_saveProjects projects, ->
        cb(project)

  _saveProjects: (projects, cb = ->) ->
    localStorage.projects = JSON.stringify(projects) if localStorage

  saveProject: (project, cb = ->) ->
    @getProjects (projects) =>
      projects.splice(@_findByID(projects, project.id), 1, project)
      @_saveProjects projects, ->
        cb(project)


  setBudget: (budget, cb = ->) ->
    localStorage.budget = JSON.stringify(budget) if localStorage
    cb()


module.exports = Storage