describe "login page", ->

  tester = null
  $ = (x) ->
    jQuery(x, tester.rootElement())


  loginInput = -> $('input[ng-model="auth.username"]')
  passwordInput = -> $('input[ng-model="auth.password"]')
  errorMessage = -> $('p.error')
  loginButton = -> $('.login .buttons button').eq(0)
  registerButton = -> $('.login .buttons button').eq(1)
  youAreLoggedAsLabelText = -> $(".footer .user-name").text()


  beforeEach ->
    ParseUtil.stubAjaxRequests()
    @addMatchers HtmlMatchers
    tester = createTester()
    tester.inject('$sniffer').history = false
    eraseLocalStorage()

  it "shall show login/password fields and no error by default", ->
    tester.visitSync "/auth", ->
      expect(loginInput()).toBeVisible()
      expect(passwordInput()).toBeVisible()
      expect(errorMessage()).toBeHidden()

  it "shall show language selector with 'en' language by default", ->
    tester.visitSync '/auth', ->
      ruLang = $('.lang-selector button[data-lang=en]')
      expect(ruLang).toExist()
      expect(ruLang).toHaveClass("selected")

  it "shall show error message when try to login without entering username/password", ->
    tester.visitSync '/auth', ->
      ParseUtil.expectLogin(username: null, password: null).andError {code: 200}
      loginButton().click()
      expect(errorMessage()).toContainText('Username is missing')

  it "shall show error message when try to login with invalid username/password", ->
    tester.visitSync '/auth', ->
      ParseUtil.expectLogin(username: null, password: null).andError {code: 101}
      loginButton().click()
      expect(errorMessage()).toContainText('Invalid username or password')

  it "shall navigate to projects page in case login succeeded", ->
    tester.visitSync '/auth', ->
      ParseUtil.expectLogin(username: "user", password: "secret")
      ParseUtil.expectBudget()
      tester.apply()
      loginInput().fill("user")
      passwordInput().fill("secret")
      loginButton().click()
      expect(tester.path()).toEqual('/')

  it "shall show user name in footer after login", ->
    tester.visitSync '/auth', ->
      ParseUtil.expectLogin(username: "superuser", password: "secret")
      ParseUtil.expectBudget()
      loginInput().fill("superuser")
      passwordInput().fill("secret")
      loginButton().click()
      expect(youAreLoggedAsLabelText()).toEqual('You are logged in as superuser')

  it "shall show error when try to register with empty username/password", ->
    tester.visitSync '/auth', ->
      registerButton().click()
      expect(errorMessage()).toContainText('Please provide both username and password for register')
      expect(registerButton()).not.toHaveClass("processing")

  it "shall not freeze register button in processing state on double error register", ->
    tester.visitSync '/auth', ->
      registerButton().click()
      registerButton().click()
      expect(registerButton()).not.toHaveClass("processing")


  it "shall register and redirect to main page", ->
    tester.visitSync '/auth', ->
      ParseUtil.expectRegister(username: "gollum", password: "precious").andReturn {objectId: "123"}
      ParseUtil.expect("GET", "https://api.parse.com/1/classes/_User/123").andReturn {objectId: "123"}
      ParseUtil.expectBudget();
      loginInput().fill("gollum")
      passwordInput().fill("precious")
      registerButton().click()
      expect(errorMessage()).toBeHidden()
      expect(registerButton()).not.toHaveClass("processing")
      expect(tester.path()).toEqual('/')


  afterEach ->
    Parse.User.logOut()
    tester.destroy()
    ParseUtil.verifyNoMoreExpectations()
    ParseUtil.unstubAjaxRequests()