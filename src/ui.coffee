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

  app.directive 'dialogPanel', ($rootScope) ->
    $rootScope.dialog = (id) ->
      $("*[show-if=" + id + "]").data("dialog")

    transclude: true
    restrict: 'E'
    replace: true
    scope:
      showIf: "@"
      onSave: "&"
      onClose: "&"
      saveButtonTitle: "="
      cancelButtonTitle: "="
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

        show: ->
          setVal scope, attrs.showIf, true
          scope.showIf = true
          setTimeout (->
            try
              el.find("input")[0].focus()
            catch ie_is_bad
              #ignore
          ), 100

        hide: (callSave, callCancel) ->
          setVal scope, attrs.showIf, false
          scope.showIf = false
          if callSave and scope.onSave
            scope.onSave()
          if callCancel and scope.onCancel
            scope.onCancel()

        save: ->
          @hide(true)
          @clearForm()

        cancel: ->
          @hide(false, true)
          @clearForm()

        clearForm: ->
          @form.find("input,textarea").val("")



      scope.$parent.$watch attrs.showIf, (newVal) ->
        if newVal then dialog.show() else dialog.hide()

      el.find("*[data-action=save]").click -> dialog.save()
      el.find("*[data-action=cancel]").click -> dialog.cancel()


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
        drop: (e, ui) ->
          ui.draggable.data("onDrop")()

      }