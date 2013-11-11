#TODO: here is the first attempt to write acceptance tests with angular+parse+ngMidwayTester.
#      it shall be cleaned out - some template for all tests which turn on parse ajax mock, fake timers, etc

async = (cb) ->
  ->
    return cb() if cb.length == 0
    done = false
    complete = -> done = true
    runs -> cb(complete)
    waitsFor -> done

doAsync = (cb) ->
  async(cb)()


eraseLocalStorage = ->
  for k, v of window.localStorage
    delete window.localStorage[k]

createTester = ->
  tester = ngMidwayTester("puzzle", {templateUrl: "/tests/index.html"})
  #Not sure why but without following line I have infinite loop of $digest in $locationWatch function
  #Probably it is related to how karma renders page in iframe, probably history api does not work properly in this case
  tester.inject('$sniffer').history = false
  tester.visitSync = (path, cb) ->
    doAsync (done) =>
      @visit path, ->
        setTimeout (->done()), 200    #Had to add this timeout. Without it tests fail time to time because some
                                      # partial templates did not loaded. Need another solution
    doAsync (done) ->
      try
        cb()
      finally
        done()
  tester


jQuery.fn.fill = (value) ->
  $(@).val(value)
  $(@).trigger 'input'
  $(@).trigger 'change'

# I cannot use jasmine.Clock because it overrides global setTimeout/setInterval, but ngMidwayTester uses them
FakeTimer =
  actions: []
  execute: ->
    for act in @actions.splice(0, @actions.length)
      act()
  executeAll: (limit = 100) ->
    for cnt in [0..limit]
      @execute()
      return if @actions.length == 0
    throw new Error("More than #{limit} times setTimeout called inside timeout function")
  init: ->
    angular.module('puzzle').provider '$timeout', ->
      $get: ->
        (fn, delay) ->
          FakeTimer.actions.push(fn)


#Standard matchers from jquery-jasmine says that any element in hidden.
HtmlMatchers = {
  toBeVisible: ->
    @actual.length && @actual.css('display') != 'none'
  toBeHidden: ->
    !@actual.length || @actual.css('display') == 'none'
  toHaveChildren: (descr) ->
    @actual.children(descr).length > 0
}


ParseUtil.expectBudget = (budget = {amount: 1000, objectId: "b1"}, projects = [], tasks = []) ->
  oid = 0
  [budget].concat(projects).concat(tasks).forEach (o) ->
    o.objectId ?= "id#{oid++}"
  ParseUtil.expectSearch("Budget", [budget])
  ParseUtil.expectSearch("Task", tasks)
  ParseUtil.expectSearch("Project2", projects)

increment = ParseUtil.increment