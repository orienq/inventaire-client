UserCommons = require 'modules/users/models/user_commons'
Transactions = require 'modules/transactions/collections/transactions'
Groups = require 'modules/network/collections/groups'
solveLang = require '../lib/solve_lang'
notificationsList = sharedLib 'notifications_settings_list'

module.exports = UserCommons.extend
  isMainUser: true
  url: ->
    app.API.user

  parse: (data)->
    # _.log data, 'data:main user parse data'
    { notifications, relations, transactions, groups, settings } = data
    @addNotifications(notifications)
    data.settings = @setDefaultSettings settings
    @relations = relations
    @transactions = new Transactions transactions
    @groups = new Groups groups
    app.vent.trigger 'transactions:unread:changes'
    return _(data).omit ['relations', 'notifications', 'transactions', 'groups']

  initialize: ->
    @setLang()
    @on 'change:language', @setLang.bind(@)
    @on 'change:username', @setPathname.bind(@)
    @on 'change:position', @setLatLng.bind(@)
    # user._id should only change once from undefined to defined
    @once 'change:_id', (model, id)-> app.execute 'track:user:id', id

  setLang: -> @lang = solveLang @get('language')

  addNotifications: (notifications)->
    if notifications?
      app.request('waitForData')
      .then app.request.bind(app, 'notifications:add', notifications)

  setDefaultSettings: (settings)->
    settings.notifications = @setDefaultNotificationsSettings(settings.notifications)
    return settings

  setDefaultNotificationsSettings: (notifications)->
    for notif in notificationsList
      notifications[notif] = notifications[notif] isnt false
    return notifications

  serializeData: (nonPrivate)->
    attrs = @toJSON()
    attrs.mainUser = true
    attrs.inventoryLength = @inventoryLength nonPrivate
    return attrs

  inventoryLength: (nonPrivate)->
    if @itemsFetched then app.request 'inventory:main:user:length', nonPrivate

  deleteAccount: ->
    console.log 'starting to play "Somebody that I use to know" and cry a little bit'

    _.preq.wrap @destroy()
    .then -> app.execute 'logout'

  # maintain the API parity with other user models
  distanceFromMainUser: -> null
