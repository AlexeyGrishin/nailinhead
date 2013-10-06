module.exports = (app) ->

  app.service 'loading', ->
    newOp = ->
      title: "Working with server"
      toString: -> @title
    operations: []
    count: 0
    onStart: (operation = newOp()) ->
      @operations.push operation
      @count++
      () =>
        @operations.splice @operations.indexOf(operation), 1
        @count--

    callback: (realCb) ->
      onEnd = @onStart
      (args...) ->
        onEnd()
        realCb(args...)


  app.directive 'loading-indicator', (loading) ->
    template:
      """
      <b>{{loading.count}}</b>
      """
    link: (scope, el, attrs) ->
      scope.loading = loading


