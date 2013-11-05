#for tests
return if (!window['require'])
{Budget, remix} = require('./tasks')
ModelMixin = require('./persistence')

module.exports = (app) ->

  app.provider 'budget', ->
    mode = 'production'
    setMode: (_mode) ->
      mode = _mode
      if mode == 'debug'
        remix(ModelMixin.parseReadonlyMixin)
      else if mode == 'local'
        remix(ModelMixin.memMixin)
    $get: ->
      Budget.mode = mode
      Budget
