error_ = require 'lib/error'
# defining all and _recalculateAll methods
aggregateUsersIds = require '../plugins/aggregate_users_ids'

module.exports = Backbone.Model.extend
  url: app.API.groups
  initialize: ->
    @initPlugins()
    { _id, name } = @toJSON()
    @set 'pathname', "/groups/#{_id}/#{name}"

    @initUsersCollection()

    # keep internal lists updated
    @on 'change:members change:admins', @_recalculateAllMembers.bind(@)
    # keep @users udpated
    @on 'change:members change:admins', @initUsersCollection.bind(@)
    @on 'change:invited', @_recalculateAllInvited.bind(@)

  initPlugins: ->
    aggregateUsersIds.call @

  initUsersCollection: ->
    # remove all users
    # to re-add all of them
    # while keeping the same object to avoid breaking references
    @users or= new Backbone.Collection
    @users.remove @users.models
    @allMembers().forEach @fetchUser.bind(@)

  fetchUser: (userId)->
    app.request 'get:group:user:model', userId
    .then @users.add.bind(@users)
    .catch _.Error('fetchMembers')

  getUserIds: (category)->
    _.inspect @, 'cant touch this'
    @get(category).map _.property('user')

  membersCount: ->
    @allMembers().length

  itemsCount: ->
    @users
    .map (user)-> user.inventoryLength() or 0
    .sum()

  serializeData: ->
    attrs = @toJSON()
    status = @mainUserStatus()
    # not using status alone as that would override users lists:
    # requested, invited etc
    attrs["status_#{status}"] = true
    _.extend attrs,
      publicDataOnly: @publicDataOnly
      membersCount: @membersCount()
      # itemsCount isnt available for public groups
      # due to an unsolved issue with user:inventoryLength in this case
      itemsCount: @itemsCount()  unless @publicDataOnly

  inviteUser: (user)->
    @action 'invite', user.id
    .then @updateInvited.bind(@, user)
    # let views catch the error

  updateInvited: (user)->
    @push 'invited',
      user: user.id
      invitor: app.user.id
      timestamp: _.now()
    user.trigger 'group:invite'

  userStatus: (user)->
    { id } = user
    if id in @allMembers() then return 'member'
    else if id in @allInvited() then return 'invited'
    else if id in @allRequested() then return 'requested'
    else 'none'

  mainUserStatus: -> @userStatus app.user
  mainUserIsAdmin: -> app.user.id in @allAdmins()
  mainUserIsMember: -> app.user.id in @allMembers()
  mainUserIsInvited: -> app.user.id in @allInvited()

  findMembership: (category, user)->
    _.findWhere @get(category), {user: user.id}

  findInvitation: (user)->
    @findMembership 'invited', user

  findUserInvitor: (user)->
    invitation = @findInvitation user
    if invitation?
      return app.request 'get:userModel:from:userId', invitation.invitor

  findMainUserInvitor: -> @findUserInvitor app.user

  acceptInvitation: ->
    @moveMembership app.user, 'invited', 'members'

    @action 'accept'
    .then @fetchGroupUsersMissingItems.bind(@)
    .catch @revertMove.bind(@, app.user, 'invited', 'members')

  declineInvitation: ->
    @moveMembership app.user, 'invited', 'declined'

    @action 'decline'
    .catch @revertMove.bind(@, app.user, 'invited', 'declined')

  # moving membership object from previousCategory to newCategory
  moveMembership: (user, previousCategory, newCategory)->
    membership = @findMembership previousCategory, user
    unless membership? then error_.new 'membership not found', arguments

    @without previousCategory, membership
    # let the possibility to just destroy the doc
    # by letting newCategory undefined
    if newCategory? then @push newCategory, membership

    if app.request 'user:isMainUser', user.id
      app.vent.trigger 'group:main:user:move'

  revertMove: (user, previousCategory, newCategory, err)->
    @moveMembership user, newCategory, previousCategory
    throw err

  fetchGroupUsersMissingItems: ->
    groupNonFriendsUsersIds = app.request 'get:non:friends:ids', @allMembers()
    _.log groupNonFriendsUsersIds, 'groupNonFriendsUsersIds'
    _.preq.get app.API.users.items(groupNonFriendsUsersIds)
    .then _.Log('groupNonFriendsUsers items')
    .then Items.add.bind(Items)
    .catch _.Error('fetchGroupUsersMissingItems err')

  requestToJoin: ->
    @createRequest()

    @action 'request'
    .catch @revertMove.bind(@, app.user, null, 'requested')

  createRequest: ->
    @push 'requested',
      user: app.user.id
      timestamp: _.now()

  cancelRequest: ->
    @moveMembership app.user, 'requested', null

    @action 'cancel-request'
    .catch @revertCancel.bind(@)

  revertCancel: (err)->
    # just re-creating the request, don't mind the timestamp
    @createRequest()
    throw err

  action: (action, userId)->
    _.preq.put app.API.groups, body
      action: action
      group: @id
      # optionel
      user: userId
