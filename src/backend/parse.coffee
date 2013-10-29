Project = Parse.Object.extend "Project"
Group = Parse.Object.extend "Group"
Report = Parse.Object.extend "Report"

Me = -> Parse.User.current()

mode = "test"

canSave = (act) -> act() if mode != "dev"

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
    canSave => project.save null, @defaultHandler (project) -> cb(project.toJSON())

  saveProject: (projectData, cb) ->
    projectObject = new Project(projectData)
    canSave => projectObject.save null, @defaultHandler(cb)

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
    canSave => Me().save @defaultHandler(cb)

  saveCurrentUser: (cb) ->
    canSave => Me().save @defaultHandler(cb)

  getBudget: (cb) ->
    cb(amount: Me().get("budget_amount"));

  setBudget: (budget, cb) ->
    oldBudget = Me().get("budget_amount")
    diff = parseFloat(budget.amount) - oldBudget
    return if diff == 0
    Me().increment("budget_amount", diff)
    canSave => Me().save @defaultHandler(cb)

  #TODO: need atomic server operations like completeTask(task), uncompleteTask(task) which will update budget as well
  # and will not touch changes in other tasks
  # or tasks shall be separate entities...

  #TODO: implement in local storage as well
  GROUP_NOT_FOUND: "group_not_found"
  getGroup: (groupName, cb) ->
    gq = new Parse.Query("Group")
    gq.equalTo("name", groupName);
    gq.equalTo("owner", Parse.User.current());
    gq.find @defaultHandler (groups) =>
      return cb(@GROUP_NOT_FOUND) if groups.length == 0
      singleGroup = groups[0]
      #here we need to access all tasks related to this group. In our case we have to get all projects
      #make caller do it
      cb(null, singleGroup.toJSON())

  saveGroup: (groupData, cb) ->
    gr = new Group(groupData)
    canSave => gr.save null, @defaultHandler(cb)

  addGroup: (groupData, cb) ->
    gr = new Group(groupData)
    gr.set("owner", Parse.User.current());
    gr.setACL(new Parse.ACL(Parse.User.current()));
    canSave => gr.save null, @defaultHandler (group) -> cb(null, group.toJSON())


  addToReport: (project, task, cb) ->
    date = task.completedDate ? new Date()
    dateKey = {year: date.getFullYear(), month: date.getMonth()}
    @_getReport dateKey, (err, report) =>
      return cb(err) if err
      report.tasks = report.tasks ? []
      report.tasks.push {
        title: task.title,
        project: project?.objectId,
        cost: task.cost,
        completionDate: date
      }
      @_saveReport(report, cb)

  _addReport: (dateKey, cb) ->
    report = new Report(dateKey)
    report.set("tasks", [])
    report.set("owner", Parse.User.current())
    report.setACL(new Parse.ACL(Parse.User.current()))
    canSave => report.save null, @defaultHandler (report) -> cb(null, report.toJSON())

  _getReport: (dateKey, cb) ->
    rq = new Parse.Query("Report")
    for key, val of dateKey
      rq.equalTo(key, val)
    rq.equalTo("owner", Parse.User.current())
    rq.find @defaultHandler (reports) =>
      if reports.length == 0
        @_addReport(dateKey, cb)
      else
        rep = reports[0]
        rep.set("tasks", rep.get("tasks") ? [])
        cb(null, rep.toJSON())

  _saveReport: (reportData, cb) ->
    report = new Report(reportData)
    canSave => report.save null, @defaultHandler cb


  removeFromReport: (task, cb) ->
    #TODO: cannot implement right now - task does not have unique id :(
    cb()

  getReport: (date, cb) ->
    dateKey = {year: date.getFullYear(), month: date.getMonth()}
    @_getReport(dateKey, cb)

module.exports = Backend
window.Backend = Backend