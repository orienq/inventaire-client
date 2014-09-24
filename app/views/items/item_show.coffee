module.exports =  class ItemShow extends Backbone.Marionette.LayoutView
  template: require 'views/items/templates/item_show'
  serializeData: -> @model.serializeData()
  regions:
    entityRegion: '#entity'
    editPanel: '#editPanel'

  onShow: ->
    entity = @model.get 'entity'
    if entity?.id?
      # ugly null null, but it's constrained by the scanner callback
      # returning /entity/:uri/add?:params
      app.execute 'show:entity', entity.id, null, null, @entityRegion

    unless @model.restricted
      editForm = new app.View.ItemEditionForm {model: @model}
      @editPanel.show editForm

  events:
    'click a.edit': 'editItem'

  editItem: -> app.execute 'show:item:form:edition', @model