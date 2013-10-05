module.exports = (app) ->

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

  #TODO: delete
  app.directive 'dialogPanelRef', ->
    scope:
      showIf: "@"
    link: (scope, el, attrs) ->
      adialog = getDialog(attrs.dialogPanelRef)
      scope.$parent.$watch attrs.showIf, (newVal) ->
        if newVal then adialog.showAt(el) else adialog.hideIfAt(el)

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
      saveButtonTitle: "="
      cancelButtonTitle: "="
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


  app.directive "deleteTo", ->
    link: (scope, el, attrs) ->
      cls = "#{attrs.deleteTo}-item"
      $(el).addClass(cls).draggable {
        revert: true
      }
      $(el).data "onDrop", ->
        if attrs.onDelete
          scope.$apply ->
            scope.$eval attrs.onDelete
      deleteTo = $("." + attrs.deleteTo)
      deleteTo.droppable {
        accept: "." + cls
        tolerance: "touch"
        hoverClass: "ready-to-drop"
        activate: ->
          deleteTo.addClass("drop-here")
        deactivate: ->
          deleteTo.removeClass("drop-here")
        drop: (e, ui) ->
          ui.draggable.data("onDrop")()

      }


  app.directive 'currency', ->
    template: "<span class='currency'>{{currency}}</span>"
    restrict: 'E'


  app.directive 'countdown', ->
    (scope, el, attrs) ->
      to = null
      target = null
      val = 0
      scope.$watch attrs.countdown, (newVal) ->
        clearTimeout(to)
        target = newVal
        el.addClass("start-counting")
        doStep = ->
          if target == val
            el.removeClass("start-counting")
          step = scope.$eval(attrs.step) ? 1
          if target > val
            val += step
            val = target if val > target
          else
            val -= step
            val = target if val < target
          el.val(val)
          to = setTimeout doStep, 10
        doStep()

  {getDialog}

