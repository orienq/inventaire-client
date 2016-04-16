# Forked from: https://github.com/KyleNeedham/autocomplete/blob/master/src/autocomplete.childview.coffee

module.exports = Marionette.ItemView.extend
  tagName: 'li'
  className: 'ac-suggestion'
  template: require './templates/suggestion'

  events:
    'click': 'select'

  modelEvents:
    'highlight': 'highlight'
    'highlight:remove': 'removeHighlight'

  highlight: -> @$el.addClass 'active'
  removeHighlight: -> @$el.removeClass 'active'

  select: (e)->
    e.preventDefault()
    e.stopPropagation()

    @model.trigger 'selected', @model