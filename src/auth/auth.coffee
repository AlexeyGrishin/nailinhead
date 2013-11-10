module.exports = (app) ->

  app.service 'auth', ['backend', '$rootScope', '$timeout', (backend, $rootScope, $timeout) ->
    loggedIn = ->
      console.log "auth:loggedIn"
      $rootScope.$broadcast 'auth:loggedIn'
    loginFailed = ->
      console.log "auth:loginFailed"
      $rootScope.$broadcast 'auth:loginFailed'
    fireEvent = (res, error) ->
      if error then loginFailed() else loggedIn()
    auth =
      loggedIn: false
      currentUser: backend.currentUser
      username: null
      password: null
      register: (username, password, options, cb) ->
        backend.register angular.extend({username, password}, options), (res, error) =>
          @loggedIn = true if not error
          fireEvent res, error
          cb(res, error)
      login: (username, password, cb) ->
        backend.login {username, password}, (res, error) =>
          @loggedIn = true if not error
          fireEvent res, error
          cb(res, error)
      logout: (cb) ->
        backend.logout =>
          @loggedIn = false
          loginFailed()
          cb()
      check: ->
        $rootScope.$broadcast 'auth:checking'
        @checking = true
        backend.getLoginStatus (loggedInFlag) =>
          $timeout =>
            @checking = false
            @loggedIn = loggedInFlag
            fireEvent loggedInFlag, !loggedInFlag
    auth
  ]
