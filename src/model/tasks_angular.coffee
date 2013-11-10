#for tests
{Budget, remix} = require('./tasks')
ModelMixin = require('./persistence')

module.exports = (app) ->

  app.run ['$rootScope', '$timeout', ($rootScope, $timeout) ->
    oldAjax = Parse._ajax
    counter = 0
    apply = ->
      counter--
      if counter <= 0
        counter = 0
        $timeout ->
          $rootScope.$apply()
          console.log "applied after Parse call"
    Parse._ajax = (args...) ->
      counter++
      p = oldAjax.call(Parse, args...)
      p.then apply, apply
      p
  ]


  app.provider 'budget', ->
    mode = 'production'
    remix(ModelMixin.parseBgMixin)
    setErrorHandler: (handler) ->
      Budget.registerGlobalErrorHandler(handler)
    setMode: (_mode) ->
      mode = _mode
      if mode == 'debug'
        console.log 'switch to readonly'
        remix(ModelMixin.parseReadonlyMixin)
      else if mode == 'local'
        console.log 'switch to memory'
        remix(ModelMixin.memMixin)
    $get: ->
      Budget.mode = mode
      budgetPromise = new Parse.Promise()
      unload: ->
        budgetPromise = new Parse.Promise()
      load: ->
        Budget.load (err, b) ->
          if err
            budgetPromise.reject(err)
          else
            budgetPromise.resolve(b)
        budgetPromise
      whenLoad: ->
        budgetPromise
      getStatusForCost: (cost) ->
        Budget.getStatusForCost(cost)

