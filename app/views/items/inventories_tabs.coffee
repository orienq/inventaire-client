module.exports = class InventoriesTabs extends Backbone.Marionette.ItemView
  template: require 'views/items/templates/inventories_tabs'

  events:
    'click #personal': -> app.execute 'show:inventory:personal'
    'click #network': -> app.execute 'show:inventory:network'
    'click #public': -> app.execute 'show:inventory:public'

  initialize: ->
    app.vent.on 'inventory:change', (filterName)->
      $('#inventoriesTabs').find('.active').removeClass('active')
      $("##{filterName}").parent().addClass('active')