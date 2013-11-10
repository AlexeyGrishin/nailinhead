async = (cb) ->
  ->
    return cb() if cb.length == 0
    done = false
    complete = -> done = true
    runs -> cb(complete)
    waitsFor -> done


describe "login page", ->

  tester = null
  find = (x) ->
    $(x, tester.rootElement()[0])

  beforeEach ->
    ParseUtil.stubAjaxRequests()
    @addMatchers {
      toBeVisible: ->
        @actual.length && @actual.css('display') != 'none'
      toBeHidden: ->
        !@actual.length || @actual.css('display') == 'none'
    }
    tester = ngMidwayTester("puzzle", {templateUrl: "/tests/index.html"})

  it "shall show login/password fields and no error by default", async (done) ->
    tester.visit "/auth", ->
      expect(find('input[ng-model="auth.username"]')).toBeVisible()
      expect(find('input[ng-model="auth.password"]')).toBeVisible()
      expect(find('p.error')).toBeHidden()
      done()

  afterEach ->
    ParseUtil.unstubAjaxRequests()