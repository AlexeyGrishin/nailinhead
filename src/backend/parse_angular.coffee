Backend = require('./parse')

module.exports = (app) ->
  app.service 'backend', ['$rootScope', ($rootScope) ->
    Backend.init()
    $(Backend).on 'backend.error', (event, error) ->
      console.error(error)
      $rootScope.$broadcast 'backend.error', error
    Backend
  ]