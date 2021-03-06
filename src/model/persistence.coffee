
ParseUtils =
  setSafe: (obj, attr, val, okCb, errCb) ->
    curVal = obj.get(attr)
    if typeof val == 'number'
      delta = val - (curVal ? 0)
      obj.increment(attr, delta)
    else
      obj.set(attr, val)
    promise = new Parse.Promise()
    promise._thenRunCallbacks({success: okCb, error: errCb})
    obj.save null, {
      success: (result) ->
        if result.get(attr) == val
          promise.resolve(result)
        else
          #rollback
          if delta isnt undefined
            obj.increment(attr, -delta)
            obj.save()
          promise.reject({code: 'conflict', message: 'Conflict occurred'})
      error: (_, error) ->
        promise.reject(error)
    }
    promise
  structToQuery: (parseClassName, data) ->
    q = new Parse.Query(parseClassName).limit(1000)
    for name, val of data
      if val == '@currentUser'
        q.equalTo(name, Parse.User.current())
      else
        q.equalTo(name, val)
    q

  afterFind: (items, options, promise) ->
    options.processItem = options.processItem ? (item) -> item
    options.postProcessItem = options.postProcessItem ? (item, cb) -> cb(item)
    loading = items.length
    res = []
    return promise.resolve(res) if loading == 0
    countdown = ->
      loading--
      if loading == 0
        promise.resolve(res)
    res = items.map options.processItem
    res.forEach (o) -> options.postProcessItem(o, countdown)


  find: (parseClassName, data, options) ->
    q = @structToQuery(parseClassName, data)
    promise = new Parse.Promise()
    promise._thenRunCallbacks(options)
    q.find().then ((items) =>
      @afterFind(items, options, promise)
    ), (error) ->
      promise.reject(error)

    promise


class BgSaver
  constructor: (options = {}) ->
    @delay = options.delay ? 1000
    @idGetter = options.idGetter ? (obj) -> obj.id
    @saver = options.saver
    @queue = []
    @to = null

  save: (obj) ->
    existentInMap = @queue.filter((q) => @idGetter(q.obj) == @idGetter(obj))[0]
    if existentInMap
      return existentInMap.promise
    promise = new Parse.Promise()
    @queue.push {obj, promise}
    clearInterval(@to)
    @to = setTimeout @_save.bind(@), @delay
    promise

  _save: ->
    for o in @queue.splice(0, @queue.length)
      (({obj, promise}) =>
        @_saveObject(obj).then ((res) -> promise.resolve(res)), (err) -> promise.reject(err)
      )(o)

  _saveObject: (obj, options) ->
    @saver.save(obj, options)

  flush: ->
    @_save()

  saveNow: (obj, options) ->
    clearTimeout(@to)
    @_save()
    @_saveObject(obj, options)


parseSaver = ->
  save: (obj, options) ->
    obj.save(null, options)
  saveNow: (obj, options) ->
    obj.save(null, options)
  flush: ->

parseBgSaver = (options = {}) ->
  options.saver = parseSaver()
  bgSaver = new BgSaver options
  save: (obj, options) ->
    bgSaver.save(obj, options)
  saveNow: (obj, options) ->
    bgSaver.saveNow(obj, options)
  flush: ->
    bgSaver.flush()

class ModelMixin
  @properties: (properties...) ->
    if properties.length > 0
      @prototype.getPropertyNames = -> properties

  save: (data, options) ->
    if options is undefined
      if data?.success
        options = data
        data = {}
      else
        options = {}

    options.data = data
    options.now = true if not @objectId
    @beforeSave()
    promise = new Parse.Promise()
    promise._thenRunCallbacks(options)
    callGlobalErrorHandler = not options.error
    delete options.success
    delete options.error
    @persistence().save(@, options).then ((json)=>
      @load(json)
      promise.resolve(@)
    ), (error) ->
      promise.reject(error)
      GlobalErrorHandler.onError(error) if callGlobalErrorHandler
    promise

  load: (data = {}) ->
    for name,val of data
      continue if @[name] == '@currentUser'   #do not touch special field

      if typeof @[name] == 'object' and typeof(val) == 'string'
        #seems like there is object in model and id in data. compare them
        if @[name].objectId == val then continue
      if @[name] isnt undefined and val is undefined
        console.error "Local value is defined, but value from server is undefined: obj == #{@constructor.name}[#{@objectId}], prop == #{name}, oldVal = #{@[name]}"
        val = @[name]
      @[name] = val

  afterLoad: (cb) ->
    cb()
  beforeSave: ->
  getPropertyNames: ->
    Object.keys(@).filter (k) ->
      typeof @[k] != 'function' &&
      k.charAt(0) != '_' &&
      k.charAt(0) != '$' &&
      k != 'persistence'
  onError: (error) ->
    GlobalErrorHandler.onError(error)

ParseClassMethods = (options = {linkToCurrentUser:true})->
  (clsName, cls, addInstanceMethods) ->
    parseClassName = cls.PARSE_CLASS ? clsName
    ParseClass = Parse.Object.extend(parseClassName)
    find: (data = {}, options = {}) ->
      ParseUtils.find parseClassName, data, {
        success: options.success,
        error: options.error,
        processItem: (item) ->
          o = new cls()
          #o._parseItem = item
          addInstanceMethods(o, item)
          o.load(item.toJSON())
          o
        postProcessItem: (item, cb) ->
          item.afterLoad(cb)
      }

    init: (obj) ->
      parseObj = new ParseClass()
      parseObj.setACL(new Parse.ACL(Parse.User.current())) if options.linkToCurrentUser
      addInstanceMethods(obj, parseObj)

    registerGlobalErrorHandler: (handler) ->
      GlobalErrorHandler.register(handler)

GlobalErrorHandler =
  handler: (error) -> console.error(error)
  register: (@handler) ->
  onError: (error) ->
    @handler(error)

parseSetAll = (parseObj, o, data) ->
  if data
    o[key] = val for key,val of data
  for prop in o.getPropertyNames().concat ["objectId"]
    if typeof o[prop] == 'number'
      parseObj.increment prop, o[prop] - (parseObj.get(prop) ? 0)
    else if o[prop] == '@currentUser'
      parseObj.set prop, Parse.User.current()
    else if o[prop] instanceof ModelMixin
      throw new Error("Refered object #{prop} shall be saved first") if not o[prop].objectId
      parseObj.set prop, o[prop].objectId
    else
      parseObj.set prop, o[prop]

ParseInstanceMethods = (saver = parseSaver()) ->
  (parseObj) ->
    save: (o, options) ->
      saverMethod = if options.now then 'saveNow' else 'save'
      if options.safe
        key = Object.keys(options.data)[0]
        o[key] = options.data[key]
        saver.flush()
        p = ParseUtils.setSafe parseObj, key, options.data[key], options.success, options.error
      else
        parseSetAll(parseObj, o, options.data)
        p = saver[saverMethod](parseObj, options)
      p2 = new Parse.Promise()
      p.then ((res) -> p2.resolve(res.toJSON())), (error) -> p2.reject(error)
      p2



ParseNowriteInstanceMethods = ->
  (parseObj) ->
    id = 1
    save: (o, options) ->
      o.objectId = "#{o.constructor.name}-#{id++}" if not o.objectId
      parseSetAll(parseObj, o, options.data)
      p = new Parse.Promise()
      p._thenRunCallbacks(options)
      p.resolve(o)
      p

MemClassMethods = ->
  (clsName, cls, addInstanceMethods) ->
    _memStorage = {}
    memStorage = (clsName) ->
      _memStorage[clsName] ?= []
      _memStorage[clsName]
    find: (data, options) ->
      p = new Parse.Promise()
      p._thenRunCallbacks(options)
      p.resolve(memStorage(clsName).filter (obj) ->
        for name,val of data
          return false if obj[name] != val and val != "@currentUser"
        true
      )
      p
    init: (o) ->
      addInstanceMethods(o, clsName, memStorage)
    registerGlobalErrorHandler: ->


MemInstanceMethods = ->
  (clsName, memStorage)->
    save: (o, options) ->
      for n,v of options.data ? {}
        o[n] = v
      if not o.objectId
        o.objectId = clsName + new Date().getTime()
        memStorage(clsName).push(o)
      p = new Parse.Promise()
      p._thenRunCallbacks(options)
      p.resolve(o)
      return p


createMixin = (mixinName, classMethods, instanceMethods) ->
  doMixin = (clsName, cls) ->
    if typeof clsName == 'object'
      classes = clsName
      doMixin clsName, cls for clsName, cls of classes
      return
    addInstanceMethods = (obj, args...) ->
      mixin = instanceMethods(args...)
      obj[mixinName] = -> mixin
    for mname, method of classMethods(clsName, cls, addInstanceMethods)
      cls[mname] = method
  doMixin

ModelMixin.parseMixin = createMixin "persistence", ParseClassMethods(), ParseInstanceMethods()
ModelMixin.parseBgMixin = createMixin "persistence", ParseClassMethods(), ParseInstanceMethods(parseBgSaver(delay: 2000))
ModelMixin.parseReadonlyMixin = createMixin "persistence", ParseClassMethods(), ParseNowriteInstanceMethods()
ModelMixin.memMixin = createMixin "persistence", MemClassMethods(), MemInstanceMethods()

this.require = false
if require
  module.exports = ModelMixin
else
  window.ModelMixin = ModelMixin