module.exports = Marionette.CollectionView.extend
  tagName: 'ul'
  className: 'usersList'
  childView: require './user_li'
  childViewOptions: ->
    groupContext: @options.groupContext
    group: @options.group
    stretch: @options.stretch
  emptyView: require './no_user'
  emptyViewOptions: ->
    message: @options.emptyViewMessage or "can't find anyone with that name"

  initialize: ->
    { filter, textFilter } = @options
    if filter? then @filter = filter

    if textFilter
      @on 'filter:text', @setTextFilter.bind(@)

  onShow: -> app.execute 'foundation:reload'

  setTextFilter: (text)->
    @filter = (model)-> model.matches text
    @render()
