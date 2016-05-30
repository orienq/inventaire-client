NotLoggedMenu = require 'modules/general/views/menu/not_logged_menu'
loginPlugin = require 'modules/general/plugins/login'
showLastPublicItems = require '../lib/show_last_public_items'
urls = require 'lib/urls'
{ tweets, articles } = require '../lib/mentions'

module.exports = Marionette.LayoutView.extend
  id: 'welcome'
  template: require './templates/welcome'
  regions:
    previewColumns: '#previewColumns'

  initialize: ->
    loginPlugin.call @

  events:
    'click .toggleMission': 'toggleMission'

  behaviors:
    AlertBox: {}
    Loading: {}
    SuccessCheck: {}

  serializeData: ->
    loggedIn: app.user.loggedIn
    urls: urls
    mentions: _.log @mentionsData(), 'mentions data'

  ui:
    topBarTrigger: '#middle-three'
    thanks: '#thanks'
    missions: 'ul.mission li'
    missionsTogglers: '.toggleMission .fa'

  onShow: ->
    @showPublicItems()
    unless app.user.loggedIn
      @hideTopBar()
      @ui.topBarTrigger.once 'inview', @showTopBar
      app.vent.trigger 'lateral:buttons:hide'

  showPublicItems: ->
    showLastPublicItems
      region: @previewColumns
      limit: 15
      allowMore: false
      assertImage: true
    .catch @hidePublicItems.bind(@)
    .catch _.Error('hidePublicItems err')

  onDestroy: ->
    app.vent.trigger 'lateral:buttons:show'
    @showTopBar()

  hidePublicItems: (err)->
    $('#lastPublicBooks').hide()
    if err? then throw err

  hideTopBar: ->
    $('.top-bar').hide()
    $('main').addClass('no-topbar')
  showTopBar: ->
    $('.top-bar').slideDown()
    $('main').removeClass('no-topbar')

  toggleMission: ->
    @ui.missions.slideToggle()
    @ui.missionsTogglers.toggle()

  mentionsData: ->
    { lang } = app.user
    return data =
      tweets: tailorForLang tweets, lang
      articles: tailorForLang articles, lang


tailorForLang = (data, lang)->
  # first the user lang
  orderedData = data[lang] or []
  # then English
  if lang isnt 'en'
    if data.en? then orderedData = orderedData.concat data.en
  # then other langs
  for k, v of data
    unless k is lang or k is 'en'
      orderedData = orderedData.concat data[k]

  return orderedData
