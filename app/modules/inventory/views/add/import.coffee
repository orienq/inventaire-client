files_ = require 'lib/files'
importers = require '../../lib/importers'
dataValidator = require '../../lib/data_validator'
ImportQueue = require './import_queue'
Candidates = require '../../collections/candidates'
behaviorsPlugin = require 'modules/general/plugins/behaviors'
forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'

module.exports = Marionette.LayoutView.extend
  id: 'importLayout'
  template: require './templates/import'
  behaviors:
    AlertBox: {}
    Loading: {}
    SuccessCheck: {}

  regions:
    queue: '#queue'

  ui:
    addedItems: '#addedItems'

  events:
    'change input[type=file]': 'getFile'
    'click input': 'hideAlertBox'
    'click #addedItems': 'showMainUserInventory'

  childEvents:
    'import:done': 'onImportDone'

  initialize: ->
    @candidates = app.items.candidates or= new Candidates

  onShow: ->
    # show the import queue if there were still candidates from last time
    @showImportQueueUnlessEmpty()
    @listenTo @candidates, 'reset', @hideImportQueueIfEmpty.bind(@)

  serializeData: ->
    importers: importers
    inventory: app.user.get('pathname')

  showImportQueueUnlessEmpty: ->
    if @candidates.length > 0
      # slide down in case @queue.$el was previously hidden
      # by hideImportQueueIfEmpty
      @queue.$el.slideDown()
      if not @queue.hasView()
        @queue.show new ImportQueue { collection: @candidates }

      _.scrollTop @queue.$el

  hideImportQueueIfEmpty: ->
    if @candidates.length is 0 then @queue.$el.slideUp()

  getFile: (e)->
    behaviorsPlugin.startLoading.call @, '.loading'
    source = e.currentTarget.id
    { parse, encoding } = importers[source]

    files_.parseFileEventAsText e, true, encoding
    .then _.Log('uploaded file')
    .tap dataValidator.bind(null, source)
    .then parse
    .catch _.ErrorRethrow('parsing error')
    # add the selector to the rejected error
    # so that it can be catched by catchAlert
    .catch error_.Complete(".warning")
    .then _.Log('parsed')
    .then @candidates.add.bind(@candidates)
    .then @showImportQueueUnlessEmpty.bind(@)
    # .then @scrollToQueue.bind(@)
    .catch forms_.catchAlert.bind(null, @)

  # passing the event to the AlertBox behavior
  hideAlertBox: -> @$el.trigger 'hideAlertBox'

  onImportDone: ->
    @hideImportQueueIfEmpty()
    @$el.trigger 'check'
    # show the message once import_queue success check is over
    setTimeout @ui.addedItems.fadeIn.bind(@ui.addedItems), 700
