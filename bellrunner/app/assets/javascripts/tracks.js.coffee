# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->

  $('#download-link').on('ajax:complete', () ->
      $('#download-link').removeClass("disabled")
      $('#ajax-loader').hide()
    )

  $('#download-link').on('ajax:beforeSend', () ->
    $('#download-link').addClass("disabled")
    $('#ajax-loader').show()
  )

  $('#download-link').on('ajax:success', (ev, data, status, xhr) ->
    window.location.href = data.url
    setTimeout("window.location.href = '/home'",1000);
  )

  $('#download-link').on('ajax:error', (event, xhr, status) ->
    if $(".alert-error").length > 0
      $(".alert-error").text(xhr.responseText)
    else
      $(".row:first > div:first").prepend("<div class='alert alert-error'>"+xhr.responseText+"</div>")
  )
