Project = Parse.Object.extend "Project"
Group = Parse.Object.extend "Group"
Report = Parse.Object.extend "Report"

Me = -> Parse.User.current()

#TODO: now here is only auth. Good time to unite this class and auth
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
      @_updateCurrentUser()
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

module.exports = Backend
window.Backend = Backend