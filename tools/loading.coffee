#<<Building>>
checkNewJs = ->
  $body = $("body")
  $.ajax("/js/index.js", {
    dataType: "text"
    content: "text"
    success: (data) ->
      if (data.indexOf("var checkNewJs") == 0)
        console.log $body.html()
        $body.html($body.html() + ".")
        setTimeout checkNewJs, 500
      else
        window.location.reload()
  })

$ ->
  $body = $("body")
  $body.html("Building.")
  checkNewJs()