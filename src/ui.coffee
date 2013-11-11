module.exports = (app, safeApply) ->

  setVal = (scope, name, val) ->
    act = ->
      scope.$parent.$eval "#{name} = #{val}"
    if scope.$root.$$phase
      act()
    else
      scope.$apply -> act()

  toggle = (scope, name) ->
    setVal scope, name, "!#{name}"

  app.directive 'dialogPanelTrigger', ->
    scope:
      dialogPanelTrigger: "@"
    link: (scope, el, attrs) ->
      #TODO: ugly. check how to change upper scope from directive
      scope.$parent.$watch attrs.dialogPanelTrigger, (newVal) ->
        $(el).toggleClass 'dialog-trigger-pressed', newVal if newVal != undefined
      $(el).click ->
        toggle scope, attrs.dialogPanelTrigger


  getDialog = (id) ->
    $("*[show-if=" + id + "]").data("dialog")


  app.directive 'dialogPanel', ->
    transclude: true
    restrict: 'E'
    replace: true
    scope:
      onSave: "&"
      onClose: "&"
      onHide: "&"
      saveButtonTitle: "@"
      cancelButtonTitle: "@"
      doNotClearForm: "@"

    template:
      """
      <div class="dialog-panel" ng-class="{shown: showIf}">
        <form class="clearfix">
          <div ng-transclude class='dialog-content'></div>
          <div class='buttons'>
            <button class='btn btn-primary' data-action="save">{{ saveButtonTitle || 'Save' }}</button>
            <button class='link' data-action="cancel">{{ cancelButtonTitle || 'Close'}}</button>
          </div>
        </form>
      </div>
      """
    link: (scope, el, attrs) ->
      dialog =
        form: el.find("form")
        origin: el.parent()

        _show: ->
          scope.showIf = true
          setTimeout (->
            try
              el.find("input")[0].focus()
            catch ie_is_bad
              #ignore
          ), 100


        showAt: (element) ->
          element.append(el) if el.parent[0] != element[0]
          setTimeout (=>
            @_show()
            scope.$apply()
          ), 0

        show: ->
          @showAt(@origin)

        hide: (callSave, callCancel) ->
          scope.showIf = false
          if callSave and scope.onSave
            scope.onSave()
          if callCancel and scope.onClose
            scope.onClose()
          if scope.onHide
            scope.onHide()

        hideIfAt: (element) ->
          @hide() if el.parent()[0] == element[0]

        save: ->
          @hide(true)
          @clearForm()

        cancel: ->
          @hide(false, true)
          @clearForm()

        clearForm: ->
          return if attrs.doNotClearForm isnt undefined
          @form.find("input,textarea").val("")



      scope.$parent.$watch attrs.showIf, (newVal) ->
        if newVal then dialog.show() else dialog.hide()

      el.find("*[data-action=save]").click ->
        dialog.save()
        scope.$apply()
      el.find("*[data-action=cancel]").click ->
        dialog.cancel()
        scope.$apply()


      el.data "dialog", dialog

  app.directive 'currency', ->
    template: "<span class='currency'>{{budget.currency}}</span>"
    restrict: 'E'

  MAX_STEPS = 100
  app.directive 'countdown', ['$timeout', ($timeout) ->
    (scope, el, attrs) ->
      to = null
      target = null
      val = 0
      inFocus = false
      setElVal = (val) ->
        if el.is("input")
          el.val(val)
        else
          el.html(formatCost(val, '&nbsp;') + "")
      el.on('focus', -> inFocus = true).on('blur', -> inFocus = false)
      scope.$watch attrs.countdown, (newVal) ->
        clearTimeout(to)
        return if inFocus
        target = parseInt(newVal)
        target = 0 if isNaN(target)
        el.addClass("start-counting")
        step = scope.$eval(attrs.step) ? 1
        step = step * 2 while (Math.abs(target - val) / step) > MAX_STEPS
        doStep = ->
          if inFocus
            val = target
          if target == val
            el.removeClass("start-counting")
            setElVal(target)
            return
          if target > val
            val += step
            val = target if val > target
          else
            val -= step
            val = target if val < target
          setElVal(val)
          to = $timeout(doStep, 10)
        doStep()
  ]

  app.directive 'uiTitle', ->
    (scope, el, attrs) ->
      el.tooltip placement: attrs.placement ? attrs.position ? "right", html: true, title: -> el.attr('ui-title')

  app.directive 'uiDialog', ->
    transclude: true
    restrict: 'E'
    replace: true
    template:
      """
      <div class="modal" role="dialog" id="help" aria-hidden='true'>
        <div class='modal-header'></div>
        <div class="modal-body" ng-transclude>
        </div>
        <div class="modal-footer">
          <button class="btn btn-primary" data-dismiss='modal'>{{closeTitle}}</button>
        </div>
      </div>
      """
    scope:
      model: "="
      closeTitle: "@"
      closeAction: "&"
    link: (scope, el, attrs) ->
      $.support.transition = false
      $(el).modal()
      $(el).modal('hide')
      $(el).on 'shown', ->
        safeApply scope, -> scope.model.show = true
      $(el).on 'hidden', ->
        safeApply scope, ->
          scope.closeAction()
          scope.model.show = false
      scope.$watch("model.show", ->
        $(el).modal(if scope.model.show then 'show' else 'hide')
      , true)


  addZeros = (num, amount) ->
    str = num + ''
    str = '0' + str while str.length < amount
    str

  formatCost = (input, separator = ' ') ->
    parts = []
    div = parseFloat(input)
    div = 0 if isNaN(div)
    return 0 if div == 0
    while div > 0
      rem = div % 1000
      div = div / 1000 |0
      parts.unshift if div > 0 then addZeros(rem, 3) else rem
    parts.join(separator)

  app.filter 'cost', -> formatCost

  app.filter 'month', ['grService', (grService) ->
    (input) ->
      grService.compile("month#{input}")
  ]

  LANG_KEY = 'NIH_language'

  app.directive 'langSelector', ['$rootScope', 'grService', ($rootScope, grService) ->
    $rootScope.currentLanguage = localStorage[LANG_KEY] ? grService.originalLanguage
    $rootScope.$on 'gr-lang-changed', (e, lang) ->
      $rootScope.currentLanguage = lang
      localStorage[LANG_KEY] = lang
    replace: true
    restrict: 'E'
    templateUrl: 'partial/language-selector.html'
    link: (scope, el, attrs) ->
      scope.languages = ['en', 'ru']
      scope.changeLanguage = (lang) ->
        grService.setLanguage lang
  ]

  #<a long-click='doAction()' processing='processing'>
  app.directive 'longClick', ->
    link: (scope, el, attr) ->
      processingByOurClick = false;
      el.addClass 'long-click'
      el.click ->
        processingByOurClick = true
        el.addClass('processing')
        scope.$apply(attr.longClick)
        if scope.$eval(attr.processing) == false
          doEnable()
      doDisable = ->
        el.attr('disabled', 'disabled') if not processingByOurClick

      doEnable = ->
        el.removeClass('processing')
        el.removeAttr('disabled')
        processingByOurClick = false

      scope.$watch attr.processing, (newVal) ->
        if newVal
          doDisable()
        else
          doEnable()

  app.provider 'status', ->
    status:
      showHelp: true
      showError: false
      error: null
    onError: (error) ->
      @status.error = error
      @status.showError = true
      @status.showHelp = false
    hideErrors: ->
      @status.error = null
      @status.showHelp = true
      @status.showError = false
    $get: -> @



  return {getDialog}


