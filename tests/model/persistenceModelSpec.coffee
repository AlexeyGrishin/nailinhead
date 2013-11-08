class Something extends ModelMixin
  @properties "a", "b"
  constructor: ({@a, @b} = {}) ->
    Something.init(@)

class Linker extends ModelMixin
  @properties "something", "b"
  constructor: ({@b})->
    Linker.init(@)

class LinkerBackReference extends ModelMixin
  @properties "linker"
  constructor: ->
    LinkerBackReference.init(@)

ModelMixin.parseMixin {Something, Linker, LinkerBackReference}

{increment} = ParseUtil

describe 'persistence model', ->

  beforeEach -> ParseUtil.stubAjaxRequests()

  it "shall be possible to create instance", ->
    s = new Something {a:3, b:4}
    expect(s.a).toEqual(3)
    expect(s.b).toEqual(4)

  it "shall save data in parse", ->
    s = new Something {a:3, b:4}
    s.a = 9
    ParseUtil.expectCreation("Something", a:increment(9), b:increment(4))
    s.save()

  it "shall not save properties not defined as @properties", ->
    s = new Something {a:3, b:4}
    s.c = 9
    ParseUtil.expectCreation("Something", a:increment(3), b:increment(4), c:undefined)
    s.save()

  describe "on safe:true", ->
    s = null
    success = null
    error = null
    beforeEach ->
      ParseUtil.expectCreation("Something", a:increment(0))
      s = new Something {a:0}
      s.save()
      success = jasmine.createSpy(->)
      error = jasmine.createSpy(->)

    it "shall call successif result value is same as expected", ->
      ParseUtil.expectSaving("Something", {a:increment(1), objectId:s.objectId}, {a: 1})
      s.save {a:1}, {safe: true, success, error}
      expect(success).toHaveBeenCalled()
      expect(error).not.toHaveBeenCalled()

    it "shall call error if result is not same as epxected and rollback", ->
      ParseUtil.expectSaving("Something", {a:increment(1), objectId:s.objectId}, {a: 4})
      ParseUtil.expectSaving("Something", {a:increment(-1), objectId:s.objectId}, {})
      s.save {a:1}, {safe: true, success, error}
      expect(success).not.toHaveBeenCalled()
      expect(error).toHaveBeenCalled()

  describe 'find', ->
    success = null
    error = null
    oldAL = null
    beforeEach ->
      success = jasmine.createSpy(->)
      error = jasmine.createSpy(->)
      oldAL = Something.prototype.afterLoad

    afterEach ->
      Something.prototype.afterLoad = oldAL

    it 'shall create objects of required class', ->
      ParseUtil.expectSearch("Something", [{objectId: "t1", a:2, b:3},{objectId: "t2", a:1, b:5}])
      Something.find {}, {success, error}
      expect(success).toHaveBeenCalled()
      expect(error).not.toHaveBeenCalled()

      tasks = success.mostRecentCall.args[0]
      expect(tasks[0] instanceof Something).toEqual(true)
      expect(tasks[1] instanceof Something).toEqual(true)
      expect(tasks[0].objectId).toEqual("t1")
      expect(tasks[0].a).toEqual(2)
      expect(tasks[1].objectId).toEqual("t2")
      expect(tasks[1].a).toEqual(1)

    it 'shall call afterLoad method for each of them', ->
      afterLoads = []
      Something.prototype.afterLoad = (cb) ->
        afterLoads.push(cb)

      ParseUtil.expectSearch("Something", [{objectId: "t1", a:2, b:3},{objectId: "t2", a:1, b:5}])
      Something.find {}, {success, error}
      expect(success).not.toHaveBeenCalled()
      expect(afterLoads.length).toEqual(2)
      afterLoads[0]()
      expect(success).not.toHaveBeenCalled()
      afterLoads[1]()
      expect(success).toHaveBeenCalled()

  describe "if objects two-way linked", ->
    l = null
    lb = null
    beforeEach ->
      l = new Linker {b:1}
      lb = new LinkerBackReference()

    it "shall save both only once", ->
      ParseUtil.expectCreation("Linker")
      l.save()
      l.something = lb
      lb.linker = l
      ParseUtil.expectCreation("LinkerBackReference", {linker: l.objectId})
      lb.save()

  describe "if uses link to another object", ->
    s = null
    l = null
    beforeEach ->
      s = new Something {a: 3}
      s.objectId = "s-2"
      l = new Linker b:1;
    it "shall send its id to server, not the object", ->
      l.something = s
      ParseUtil.expectCreation("Linker", {something: "s-2", b:increment(1)})
      l.save()
    it "shall not replace object with same id", ->
      l.something = s
      l.load b:5, something: "s-2"
      expect(l.b).toEqual(5)
      expect(l.something).toBe(s)
    it "shall replace object with other id", ->
      l.something = s
      l.load b:5, something: "s-3"
      expect(l.b).toEqual(5)
      expect(l.something).toEqual("s-3")

  afterEach ->
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()

values = (o) ->
  return o.map(values) if o.length isnt undefined
  v = {}
  for own name, val of o
    continue if typeof val == 'function'
    v[name] = val?.objectId ? val
  v

describe 'parseReadonly', ->

  ok = err = null
  beforeEach ->
    ModelMixin.parseReadonlyMixin {Something, Linker, LinkerBackReference}
    ParseUtil.stubAjaxRequests()
    ok = jasmine.createSpy()
    err = jasmine.createSpy()

  afterEach ->
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()

  it "shall allow to search something on server", ->
    ParseUtil.expectSearch "Something", [{a: 3, objectId: 4}]
    Something.find().then ((s) ->
      expect(s.map (s) -> s.objectId).toEqual([4])
    ), (err) ->
      expect(err).toBeNull()

  it "shall not call server on save", ->
    s = new Something {a:3}
    s.save().then ok, err
    expect(err).not.toHaveBeenCalled()
    expect(ok).toHaveBeenCalled()

  it "shall process linked objects without error", ->
    l = new Linker {b: 4}
    s = new Something {a: 1}
    l.something = s
    s.save().then ok, err
    l.save().then ok, err
    expect(err).not.toHaveBeenCalled()
    expect(ok).toHaveBeenCalled()

  it "shall process two-way linked objects without error", ->
    l = new Linker {b:4}
    l2 = new LinkerBackReference()
    l.save().then ok, err
    l.something = l2
    l2.linker = l
    l2.save().then ok, err
    expect(err).not.toHaveBeenCalled()
    expect(ok).toHaveBeenCalled()



describe 'memoryPersistence', ->

  ok = err = null
  beforeEach ->
    ModelMixin.memMixin {Something, Linker, LinkerBackReference}
    ok = jasmine.createSpy()
    err = jasmine.createSpy()

  it "shall allow to create and save", ->
    s = new Something {a: 3}
    s.save()
    expect(s.objectId).toBeDefined()

  it "shall allow to search all", ->
    s = new Something {a: 3}
    s.save()
    Something.find().then ((objects) ->
      expect(objects.map(values)).toEqual([s].map(values))
    ), (err) ->
      expect(err).toBeNull()

  it "shall allow to search by criteria", ->
    s = new Something {a: 4}
    s.save()
    Something.find({a: 4}).then ((objects) ->
      expect(objects.map(values)).toEqual([s].map(values))
    ), (err) ->
      expect(err).toBeNull()

  it "shall return empty array if nothing found", ->
    s = new Something {a: 4}
    s.save()
    Something.find({a: 3}).then ((objects) ->
      expect(objects.map(values)).toEqual([])
    ), (err) ->
      expect(err).toBeNull()

  it "shall process linked objects without error", ->
    l = new Linker {b: 4}
    s = new Something {a: 1}
    l.something = s
    l.save().then ok, err
    expect(err).not.toHaveBeenCalled()
    expect(ok).toHaveBeenCalled()

  it "shall process two-way linked objects without error", ->
    l = new Linker {b:4}
    l2 = new LinkerBackReference()
    l.something = l2
    l2.linker = l
    l.save().then ok, err
    expect(err).not.toHaveBeenCalled()
    expect(ok).toHaveBeenCalled()
