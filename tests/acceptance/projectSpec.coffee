describe 'project page', ->
  tester = null
  $ = (x) -> jQuery(x, tester.rootElement())

  taskList = -> $('ul.tasks-list')

  beforeEach ->
    @addMatchers HtmlMatchers
    ParseUtil.stubAjaxRequests()
    eraseLocalStorage()
    FakeTimer.init()

  afterEach ->
    #TODO: DRY through all acceptance tests
    Parse.User.logOut()
    tester.destroy()
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()


  describe 'if not logged in', ->
    beforeEach ->
      tester = createTester()

    it 'shall redirect to auth', ->
      tester.visitSync '/12345', ->
        FakeTimer.execute()
        expect(tester.path()).toEqual('/auth')


  describe 'if logged in and no tasks in project', ->
    beforeEach ->
      ParseUtil.setLoggedIn()
      tester = createTester()
      ParseUtil.expectBudget {amount:111}, [{name: "Project1", objectId: "12345"}], []

    it "shall redirect to main if project id is unknown", ->
      tester.visitSync '/12345_', ->
        FakeTimer.executeAll()
        expect(tester.path()).toEqual('/')

    it 'shall show stay on project page if id is known', ->
      tester.visitSync '/12345', ->
        FakeTimer.executeAll()
        expect(tester.path()).toEqual('/12345')
        expect($(".top-panel h3").text().trim()).toEqual("Project1")

    it 'shall show adding task panel', ->
      tester.visitSync '/12345', ->
        FakeTimer.executeAll()
        expect($("button.add-new-task")).toHaveClass("dialog-trigger-pressed")
        expect($(".add-task-dialog").parent()).toBeVisible()

    addTaskTitleInput = -> $(".add-task-dialog input[ng-model='newTask.title']")
    addTaskCostInput = -> $(".add-task-dialog input[ng-model='newTask.cost1']")
    addTaskAmountInput = -> $(".add-task-dialog input[ng-model='newTask.amount']")
    addTotal = -> $(".add-task-dialog label.total").text().split('=')[1].trim()
    addTaskSave = -> $(".add-task-dialog button[data-action=save]")

    it 'shall show empty title, zero cost and amount = 1', ->
      tester.visitSync '/12345', ->
        FakeTimer.executeAll()
        expect(addTotal()).toEqual("0")
        expect(addTaskTitleInput()).toHaveValue("")
        expect(addTaskCostInput()).toHaveValue("0")
        expect(addTaskAmountInput()).toHaveValue("1")

    it 'shall add task when enter task title and cost', ->
      tester.visitSync '/12345', ->
        FakeTimer.executeAll()
        addTaskTitleInput().fill("Gravicapa")
        addTaskCostInput().fill("10000")
        addTaskAmountInput().fill("2")
        expect(addTotal()).toEqual("20 000")
        ParseUtil.expectCreation("Task", {title: "Gravicapa", cost: increment(20000), amount: increment(2)})
        addTaskSave().click()

    it 'shall reset values after task is added', ->
      tester.visitSync '/12345', ->
        FakeTimer.executeAll()
        addTaskTitleInput().fill("Gravicapa")
        addTaskCostInput().fill("10000")
        addTaskAmountInput().fill("2")
        ParseUtil.expectCreation("Task", {title: "Gravicapa", cost: increment(20000), amount: increment(2)})
        addTaskSave().click()
        expect(addTotal()).toEqual("0")
        expect(addTaskTitleInput()).toHaveValue("")
        expect(addTaskCostInput()).toHaveValue("0")
        expect(addTaskAmountInput()).toHaveValue("1")

