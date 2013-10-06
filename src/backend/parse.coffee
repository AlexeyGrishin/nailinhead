Project = Parse.Object.extend "Project"

Me = -> Parse.User.current()

Backend =

  currentUser: {}

  init: ->
    Parse.initialize 'eXTzA1h8G4j7HzEpKbsHpJh4ZbzpkFKRzxn50gJp', 'vJpkQiAsEzDuoNGjRPUr0xcbgP2g7G4nnnQax7Mf'


  getLoginStatus: (cb) ->
    authenticated = Me()?.authenticated()
    if not authenticated
      Parse.User.logOut()
      cb(authenticated)
    else
      @_updateCurrentUser ->
        cb(authenticated)


  _updateCurrentUser: (cb = ->) ->
    return cb() if Me() is null
    Me().fetch {
      success: =>
        angular.copy Me()?.toJSON(), @currentUser
        cb()
    }


  register: (userData, cb) ->
    user = new Parse.User(userData)
    user.signUp null, @defaultHandler (user, error) =>
      @_updateCurrentUser ->
        cb(user, error)



  login: (userData, cb) ->
    Parse.User.logIn userData.username, userData.password, @defaultHandler (res, error) =>
      @_updateCurrentUser ->
        cb(res, error)

  logout: (cb) ->
    Parse.User.logOut()
    angular.copy {}, @currentUser
    cb()

  loading: 0

  defaultHandler: (successCb = ->) ->
    @loading++
    success: (data) =>
      successCb(data)
      @loading--
    error: (_, error) =>
      $(@).trigger "backend.error", error
      successCb(null, error)
      @loading--

  getProjects: (cb) ->
    pq = new Parse.Query(Project)
    pq.equalTo("owner", Parse.User.current())
    pq.ascending("createdAt")
    pq.find @defaultHandler (projects) =>
      @projects = projects
      cb(projects.map (p) -> p.toJSON())

  addProject: (projectData, cb) ->
    project = new Project(projectData)
    project.set("owner", Parse.User.current());
    project.setACL(new Parse.ACL(Parse.User.current()));
    project.save null, @defaultHandler (project) -> cb(project.toJSON())

  saveProject: (projectData, cb) ->
    if projectData.completed
      projectData = projectData
    projectObject = new Project(projectData)
    projectObject.save null, @defaultHandler(cb)

  deleteProject: (projectData, cb) ->
    projectObject = new Project(projectData)
    projectObject.destroy @defaultHandler(cb)

  fetchProject: (projectData, cb) ->
    projectObject = new Project(projectData)
    projectObject.fetch @defaultHandler (project) -> cb(project.toJSON())


  getOptions: (cb) ->
    cb(Me().get("options"))

  setOptions: (options, cb) ->
    Me().set("options", options)
    Me().save @defaultHandler(cb)

  saveCurrentUser: (cb) ->
    Me().save @defaultHandler(cb)

  getBudget: (cb) ->
    cb(Me().get("budget"));

  setBudget: (budget, cb) ->
    Me().set("budget", budget)
    Me().save @defaultHandler(cb)

module.exports = Backend
window.Backend = Backend