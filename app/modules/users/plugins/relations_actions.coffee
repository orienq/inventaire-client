# REQUIRED:
# - ConfirmationModal behavior

behaviorsPlugin = require 'modules/general/plugins/behaviors'

events =
  # general actions
  'click .cancel': 'cancel'
  'click .discard': 'discard'
  'click .accept': 'accept'
  'click .request': 'send'
  'click .unfriend': 'unfriend'
  # group actions
  'click .invite': 'invite'
  'click .acceptRequest': 'acceptRequest'
  'click .refuseRequest': 'refuseRequest'
  'click .makeAdmin': 'makeAdmin'
  'click .kick': 'kick'

confirmAction = (actionLabel, actionFn)->
  confirmationText = _.i18n "#{actionLabel}_confirmation",
    username: @model.get 'username'

  @$el.trigger 'askConfirmation',
    confirmationText: confirmationText
    warningText: null
    action: actionFn

confirmUnfriend = ->
  confirmAction.call @, 'unfriend', app.request.bind(app, 'unfriend', @model)

handlers =
  cancel: -> app.request 'request:cancel', @model
  discard: -> app.request 'request:discard', @model
  accept: -> app.request 'request:accept', @model
  send: ->
    username = @model.get 'username'
    if app.request 'require:loggedIn', "inventory/#{username}"
      app.request 'request:send', @model
  unfriend: confirmUnfriend
  invite: ->
    unless @group? then return _.error 'inviteUser err: group is missing'

    @group.inviteUser @model
    .catch behaviorsPlugin.Fail.call(@, 'invite user')

  acceptRequest: ->
    unless @group? then return _.error 'acceptRequest err: group is missing'

    @group.acceptRequest @model
    .catch behaviorsPlugin.Fail.call(@, 'accept user request')

  refuseRequest: ->
    unless @group? then return _.error 'refuseRequest err: group is missing'

    @group.refuseRequest @model
    .catch behaviorsPlugin.Fail.call(@, 'refuse user request')

  makeAdmin: ->
    unless @group? then return _.error 'makeAdmin err: group is missing'
    actionFn = @group.makeAdmin.bind @group, @model
    confirmAction.call @, 'group_make_admin', actionFn

  kick: ->
    unless @group? then return _.error 'kick err: group is missing'
    actionFn = @group.kick.bind @group, @model
    confirmAction.call @, 'group_ban', actionFn

module.exports = _.BasicPlugin events, handlers
