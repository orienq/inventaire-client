module.exports = class SignupStep1 extends Backbone.Marionette.ItemView
  tagName: 'div'
  template: require 'views/user/templates/signup_step1'
  onShow: -> app.commands.execute 'modal:open'
  behaviors:
    AlertBox: {}
    SuccessCheck: {}

  events:
    'click #verifyUsername': 'verifyUsername'
    'keydown #username': 'closeAlertBoxIfVisible'

  verifyUsername: (e)->
    username = $('#username').val()
    $.post app.API.auth.username, {username: username}
    .then (res)=>
      @model.set('username', res.username)
      @$el.trigger 'check', -> app.commands.execute 'signup:validUsername'
    .fail (err)=>
      @invalidUsername(err)

  invalidUsername: (err)=>
    errMessage = err.responseJSON.status_verbose || "invalid username"
    @$el.trigger 'alert', {message: errMessage}


  closeAlertBoxIfVisible: ->
    @$el.trigger 'hideAlertBox'