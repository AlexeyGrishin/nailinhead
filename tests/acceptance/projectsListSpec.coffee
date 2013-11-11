describe 'projects page', ->
  tester = null
  $ = (x) -> jQuery(x, tester.rootElement())

  budgetElement = -> $(".header .budget .amount")
  bookingElement = -> $(".header .groups")
  budgetAmount = -> parseInt($(".header .budget .amount").text().replace(/[^0-9]/gi, ''))
  bookingAmount = -> $(".header .groups span").eq(0)

  projectsList = -> $("ul.projects-list")
  project = (idx) -> projectsList().children("li").eq(idx)

  beforeEach ->
    @addMatchers HtmlMatchers
    ParseUtil.stubAjaxRequests()
    eraseLocalStorage()
    FakeTimer.init()

  afterEach ->
    Parse.User.logOut()
    tester.destroy()
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()


  describe 'if not logged in', ->
    beforeEach ->
      tester = createTester()

    it 'shall redirect to auth', ->
      tester.visitSync '/', ->
        FakeTimer.execute()
        expect(tester.path()).toEqual('/auth')

  describe 'if logged in', ->
    beforeEach ->
      ParseUtil.setLoggedIn()
      tester = createTester()

    describe 'and no projects', ->
      beforeEach ->
        ParseUtil.expectBudget {amount: 555}

      it 'shall show budget amount', ->
        tester.visitSync '/', ->
          FakeTimer.executeAll()
          expect(tester.path()).toEqual('/')
          expect(budgetElement()).toBeVisible()
          expect(budgetAmount()).toEqual(555)

      it 'shall not show booked amount', ->
        tester.visitSync '/', ->
          FakeTimer.executeAll()
          expect(bookingElement()).toBeHidden()

      it 'shall show zero projects', ->
        tester.visitSync '/', ->
          FakeTimer.executeAll()
          expect(projectsList()).not.toHaveChildren("li")

      it 'shall be on projects tab', ->
        tester.visitSync '/', ->
          FakeTimer.executeAll()
          expect($(".footer .nav li").eq(0)).toHaveClass("selected")

