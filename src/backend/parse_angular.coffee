Backend = require('./parse')

module.exports = (app) ->
  app.service 'backend', ['$rootScope', ($rootScope) ->
    b = Backend()
    b.init()
    $(b).on 'backend.error', (event, error) ->
      console.error(error)
      $rootScope.$broadcast 'backend.error', error
    b
  ]