# Forked from: https://github.com/KyleNeedham/autocomplete/blob/master/src/autocomplete.collectionview.coffee

module.exports = Marionette.CompositeView.extend
  template: require './templates/suggestions'
  className: 'ac-suggestions hidden'
  childViewContainer: 'ul'
  emptyView: require './no_suggestion'