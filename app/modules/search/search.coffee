Searches = require './collections/searches'
SearchLayout = require './views/search'
error_ = require 'lib/error'

module.exports =
  define: (module, app, Backbone, Marionette, $, _)->
    SearchRouter = Marionette.AppRouter.extend
      appRoutes:
        'search': 'searchFromQueryString'

    app.addInitializer ->
      new SearchRouter
        controller: API

  initialize: ->
    app.commands.setHandlers
      'search:global': API.search

    app.reqres.setHandlers
      'search:entities': API.searchEntities

    # keep an history of searches
    app.searches = new Searches

API = {}
API.search = (query)->
  unless _.isNonEmptyString query
    app.execute 'show:add:layout:search'
    return

  searchLayout = new SearchLayout { query }

  docTitle = "#{query} - " +  _.i18n('Search')
  app.layout.main.Show searchLayout, docTitle
  encodedQuery = _.fixedEncodeURIComponent query
  app.navigate "search?q=#{encodedQuery}"

API.searchFromQueryString = (querystring)->
  { q } = _.parseQuery querystring
  # replacing "+" added that the browser search might have added
  q = q.replace /\+/g, ' '
  API.search q
