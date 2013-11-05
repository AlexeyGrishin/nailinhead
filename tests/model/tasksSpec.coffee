prepareBudget = (amount) ->
  withCompletedTask: (cost) ->
    @withTask cost, 1
  withGroupedTasks: (cgPairs) ->
    ParseUtil.expectSearch("Budget", [{amount: amount, objectId: "b1"}])
    ParseUtil.expectSearch("Task", cgPairs.map (cg, idx) ->
      t = objectId: "t#{idx}", title: "task #{idx}", cost: cg.cost, completed: cg.completed ? 0, project: "p1"
      t.groups = [cg.group] if cg.group
      t
    )
    ParseUtil.expectSearch("Project2", [{name: "Project 1", objectId: "p1"}])
    andThen: (cb) ->
      Budget.load (err, b) -> cb(b)
  withTask: (cost, completed = 0) ->
    ParseUtil.expectSearch("Budget", [{amount: amount, objectId: "b1"}])
    ParseUtil.expectSearch("Task", [{objectId: "t1", title: "task", cost: cost, completed: completed, project: "p1"}])
    ParseUtil.expectSearch("Project2", [{name: "Project 1", objectId: "p1"}])
    andThen: (cb) ->
      Budget.load (err, b) -> cb(b, b.tasks[0], b.projects[0])

describe 'budget', ->

  beforeEach ->
    ParseUtil.stubAjaxRequests()

  afterEach ->
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()

  it 'shall be possible to create', ->
    b = new Budget amount: 3
    expect(b.amount).toEqual(3)

  describe "when loading first time", ->
    beforeEach ->
      ParseUtil.expectSearch("Budget", [{amount: 10}])
      ParseUtil.expectSearch("Task", [{objectId: "t1", title: "a", cost: "5", completed: 0, project: "p1"}])
      ParseUtil.expectSearch("Project2", [{name: "Project 1", objectId: "p1"}])

    it 'shall load without error', ->
      Budget.load (err, b) ->
        expect(err).toBeNull()
        expect(b.amount).toEqual(10)

    it 'shall load all tasks as well', ->
      Budget.load (err, b) ->
        expect(b.tasks).toBeDefined()
        expect(b.tasks.map (t) -> _.pick(t, 'objectId', 'title', 'completed', 'deleted', 'cost')).toEqual [{
          objectId: "t1", title: "a", cost: 5, completed: 0, deleted: 0
        }]

    it "shall load projects as well", ->
      Budget.load (err, b) ->
        expect(b.projects).toBeDefined()
        expect(b.projects.map (p) -> _.pick(p, 'objectId', 'name', 'deleted')).toEqual [{
          objectId: 'p1', name: 'Project 1', deleted: 0
        }]

    it 'shall propagate links to project and self', ->
      Budget.load (err, b) ->
        task = b.tasks[0]
        project = b.projects[0]
        expect(task.budget).toBe(b)
        expect(project.budget).toBe(b)
        expect(task.project).toBe(project)
        expect(project.tasks).toEqual([task])

  describe 'task status', ->

    it "shall be 'unavailable' when budget is not enough", ->
      prepareBudget(10).withTask(11).andThen (b, task) ->
        expect(task.status).toEqual('unavailable')

    it "shall be 'available' when budget is enough", ->
      prepareBudget(10).withTask(10).andThen (b, task) ->
        expect(task.status).toEqual('available')

    it "shall be 'completed' when task is completed", ->
      prepareBudget(10).withCompletedTask(5).andThen (b, task) ->
        expect(task.status).toEqual('completed')

    it "shall be changed on task's cost change", ->
      prepareBudget(10).withTask(11).andThen (b, task) ->
        task.withStatusUpdate (t) ->t.cost = 5
        expect(task.status).toEqual('available')
        task.withStatusUpdate (t) ->t.cost = 15
        expect(task.status).toEqual('unavailable')

    it "shall be changeds on budget change", ->
      prepareBudget(10).withTask(3).andThen (b, task) ->
        ParseUtil.expectSaving("Budget", {objectId: b.objectId})
        ParseUtil.expectSaving("Budget", {objectId: b.objectId})
        b.set 2
        expect(task.status).toEqual('unavailable')
        b.set 5
        expect(task.status).toEqual('available')

  it "shall decrease when task is completed", ->
    prepareBudget(10).withTask(3).andThen (b, task) ->
      ParseUtil.expectSaving("Task", {objectId: task.objectId, completed: increment(1)}, {completed: 1})
      ParseUtil.expectSaving("Task", {objectId: task.objectId}, {})
      ParseUtil.expectSaving("Budget", {objectId: b.objectId, amount: increment(-3)}, {})
      task.complete()
      expect(task.status).toEqual('completed')
      expect(b.amount).toEqual(7)

  it "shall increase budget back when task is uncompleted", ->
    prepareBudget(10).withCompletedTask(5).andThen (b, task) ->
      ParseUtil.expectSaving("Task", {objectId: task.objectId, completed: increment(-1)}, {completed: 0})
      ParseUtil.expectSaving("Budget", {objectId: b.objectId, amount:increment(+5)}, {})
      task.uncomplete()
      expect(task.status).toEqual('available')
      expect(b.amount).toEqual(15)

  it "shall NOT change budget if completion does not match", ->
    prepareBudget(10).withTask(5).andThen (b, task) ->
      ParseUtil.expectSaving("Task", {objectId: task.objectId, completed: increment(+1)}, {completed: 2})
      ParseUtil.expectSaving("Task", {objectId: task.objectId, completed: increment(-1)}, {completed: 1})
      task.complete()
      expect(b.amount).toEqual(10)
      expect(task.status).toEqual("completed")

  describe "add task to project", ->

    it "shall create task on server with links to budget and project", (done)->
      prepareBudget(10).withTask(4).andThen (b, task, project) ->
        ParseUtil.expectCreation("Task", {title: "test", cost: increment(4), budget: b.objectId, project: project.objectId, completed: increment(0), deleted: increment(0)})
        project.addTask {title: "test", cost: 4}, (err, task) ->
          expect(err).toBeNull()
          expect(task.project).toBe(project)
          expect(task.budget).toBe(b)
          expect(task.status).toEqual("available")



  describe "group 'booked'", ->

    values = (o) ->
      return o.map(values) if o.length isnt undefined
      v = {}
      for own name, val of o
        continue if typeof val == 'function'
        v[name] = val?.objectId ? val
      v

    it "shall have zero amount if no tasks inside it", ->
      prepareBudget(10).withGroupedTasks([{cost: 3}, {cost: 2}]).andThen (b) ->
        expect(b.booked.tasks().map(values)).toEqual([])
        expect(b.booked.amount()).toEqual(0)

    it "shall have sum of tasks costs", ->
      prepareBudget(10).withGroupedTasks([{cost: 3, group: 'booked'}, {cost: 2, group: 'booked'}, {cost: 3}]).andThen (b) ->
        expect(b.booked.tasks().map(values)).toEqual(values([b.tasks[0], b.tasks[1]]))
        expect(b.booked.amount()).toEqual(5)

    it "shall include only non-completed tasks", ->
      prepareBudget(10).withGroupedTasks([{cost: 3, group: 'booked', completed: 1}, {cost: 2, group: 'booked'}]).andThen (b) ->
        expect(b.booked.tasks().map(values)).toEqual(values([b.tasks[1]]))
        expect(b.booked.amount()).toEqual(2)


  describe "deletion of task", ->

    it "shall remove task from list of project's tasks", ->
      prepareBudget(10).withTask(5).andThen (b, task, project) ->
        ParseUtil.expectSaving "Task", {deleted: increment(1), objectId: task.objectId}
        project.deleteTask(task)
        expect(project.tasks.map(values)).toEqual([])

    it "shall remove task from list of group's tasks", ->
      prepareBudget(10).withGroupedTasks([{cost: 3, group: "booked"}]).andThen (b) ->
        task = b.tasks[0]
        expect(b.booked.tasks().map(values)).toEqual(values([task]))
        ParseUtil.expectSaving "Task", {deleted: increment(1), objectId: task.objectId}
        task.delete()
        expect(b.booked.tasks().map(values)).toEqual([])


