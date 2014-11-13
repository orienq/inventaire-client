RequestsList = require 'modules/users/views/requests_list'
NotificationsList = require 'modules/notifications/views/notifications_list'

module.exports = class AccountMenu extends Backbone.Marionette.LayoutView
  template: require 'views/menu/templates/account_menu'
  events:
    'click #edit, #pic': -> app.execute 'show:user:edit'
    'click #logout': -> app.execute 'persona:logout'

  serializeData: ->
    attrs =
      search:
        nameBase: 'search'
        field:
          placeholder: _.i18n 'Search for books or people'
        button:
          icon: 'search'
          classes: 'secondary'
    return _.extend attrs, @model.toJSON()

  initialize: ->
    @addRegion 'requests', app.Region.CommonEl.extend {el: '#requests'}
    @addRegion 'notifs', app.Region.CommonEl.extend {el: '#notifications'}

  onShow: ->
    app.execute 'foundation:reload'
    @showRequests()
    @showNotifications()

  showRequests: ->
    view = new RequestsList
      collection: app.users.othersRequests
      el: '#requests'
    @requests.show view

  showNotifications: ->
    view = new NotificationsList
      collection: app.user.notifications
      el: '#notifications'
    @notifs.show view