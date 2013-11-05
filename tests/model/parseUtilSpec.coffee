describe 'parseUtil', ->

  beforeEach ->
    ParseUtil.stubAjaxRequests(@)

  afterEach ->
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()

  it 'shall be defined', ->
    expect(ParseUtil).toBeDefined()

  it 'shall expect object saving', ->
    ParseUtil.expect("POST", "https://api.parse.com/1/classes/NewClass", {a:"b"}).andReturn {a:"b", objectId: "abc4"}
    NewClass = Parse.Object.extend("NewClass")
    o = new NewClass a:"b"
    expect(o.id).toBeUndefined()
    o.save null, {
      success: ->
        expect(o.id).toEqual("abc4")
    }

  it "shall fail if expected call not occurred", ->

    expect(->
      ParseUtil.expect("POST", "https://api.parse.com/1/classes/NewClass", {a:"b"}).andReturn {a:"b", objectId: "abc4"};
      ParseUtil.verifyNoMoreExpectations()
    ).toThrow()


  it "shall fail if method is not as expected", ->
    ParseUtil.expect("GET", "https://api.parse.com/1/classes/NewClass", {}).andReturn {}
    NewClass = Parse.Object.extend("NewClass")
    o = new NewClass a:"b"
    expect( ->o.save()).toThrow()

  it "shall fail if url is not as expected", ->
    ParseUtil.expect("POST", "https://api.parse.com/1/classes/OldClass", {}).andReturn {}
    NewClass = Parse.Object.extend("NewClass")
    o = new NewClass a:"b"
    expect( ->o.save()).toThrow()

  it "shall fail if data is not as expected", ->
    ParseUtil.expect("POST", "https://api.parse.com/1/classes/NewClass", {a: "b"}).andReturn {}
    NewClass = Parse.Object.extend("NewClass")
    o = new NewClass a:"c"
    expect( ->o.save()).toThrow()

  it "shall fail if nexted data object is not as expected", ->
    ParseUtil.expect("POST", "https://api.parse.com/1/classes/NewClass", {a: {op: "inc", val: 3}}).andReturn {}
    NewClass = Parse.Object.extend("NewClass")
    o = new NewClass a:{op: "inc", val: 5}
    expect( ->o.save()).toThrow()


