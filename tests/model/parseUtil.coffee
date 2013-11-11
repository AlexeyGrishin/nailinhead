
expectations = []

expectation = (method, url, dataPart) ->
  toString: ->
    "#{method} #{url}"
  check: (compare, gmethod, gurl, gdata) ->
    msg = "Ajax call #{gmethod} #{gurl} does not match expectation.\n Data = #{gdata}"
    gdata = JSON.parse(gdata) if typeof gdata == 'string'
    return false if not compare(method, gdata._method ? gmethod, msg, "method")
    return false if not compare(url, gurl, msg, "url")
    for name,val of dataPart
      return false if not compare(
        JSON.stringify(dataPart[name]),
        JSON.stringify(gdata[name]),
        msg,
        "data.#{name}")
    return true
  andReturn: (json) ->
    @returnVal = json
    @
  andError: (error) ->
    @returnErr = {responseText: JSON.stringify(error)}
    @
  process: (promise) ->
    return promise.reject(@returnErr) if @returnErr
    promise.resolve(@returnVal ? {})

ParseUtil =
  oldPA: null

  increment: (val) ->
    __op: "Increment", amount: val

  stubAjaxRequests: (@jasmine) ->
    return if @oldPA isnt null
    Parse.initialize "id1", "id2"
    @oldPA = Parse._ajax
    expectations = []
    Parse._ajax = @_ajax

  unstubAjaxRequests: ->
    return if @oldPA is null
    Parse._ajax = @oldPA
    @oldPA = null

  _compare: (o1, o2, message, field) ->
    if o1 != o2
      throw new Error("#{message}. \n#{field}:\n Expected : #{o1}\n  but got : #{o2}")
    true

  _fail: (message) ->
    throw new Error(message)


  _ajax: (method, url, data, success, error) ->
    return ParseUtil._fail("No more requests expected, but there is #{method} #{url}") if expectations.length == 0
    nextExpectation = expectations.shift()
    if nextExpectation.check(ParseUtil._compare, method, url, data)
      promise = new Parse.Promise()
      promise._thenRunCallbacks({success, error})
      nextExpectation.process(promise)
      promise


  expect: (method, url, dataPart) ->
    e = expectation(method, url, dataPart)
    expectations.push(e)
    e

  expectCreation: (cls, objectData, resultData = {}) ->
    resultData.objectId ?= "#{cls}-#{new Date().getTime()}"
    @expect("POST", "https://api.parse.com/1/classes/#{cls}", objectData).andReturn resultData

  expectSaving: (cls, objectData, resultData = {}) ->
    resultData.objectId = objectData.objectId
    delete objectData.objectId
    @expect("PUT", "https://api.parse.com/1/classes/#{cls}/#{resultData.objectId}", objectData).andReturn resultData

  expectSearch: (cls, result) ->
    @expect("GET", "https://api.parse.com/1/classes/#{cls}").andReturn results:result

  expectGetUser: (result) ->
    @expect("GET", "https://api.parse.com/1/users").andReturn result

  expectLogin: (incoming) ->
    @expect("GET", "https://api.parse.com/1/login", incoming).andReturn {objectId: "user1", sessionToken: "session1"}

  expectRegister: (incoming, result) ->
    @expect("POST", "https://api.parse.com/1/users", incoming).andReturn result

  setLoggedIn: ->
    Parse.User._currentUserMatchesDisk = false
    window.localStorage["Parse/eXTzA1h8G4j7HzEpKbsHpJh4ZbzpkFKRzxn50gJp/currentUser"] =
      """
      {"username":"Uef","objectId":"12345","createdAt":"2013-10-06T00:46:17.458Z","updatedAt":"2013-11-07T00:19:00.362Z","_id":"12345","_sessionToken":"yeq5vcczrts2ckc5hlpb9gsvy"}
      """
    window.localStorage["Parse/eXTzA1h8G4j7HzEpKbsHpJh4ZbzpkFKRzxn50gJp/installationId"] = Parse._getInstallationId()

  verifyNoMoreExpectations: ->
    return if expectations.length == 0
    message = expectations.map((e) ->
      e.toString()
    ).join("\n")
    expectations = []
    throw new Error("Following requests expected but did not occured:\n" + message)

