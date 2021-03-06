Entity = require './entity'
books_ = require 'lib/books'

module.exports = Entity.extend
  prefix: 'isbn'
  initialize: ->
    @initLazySave()

    # should expect data coming from both google books
    # and the local entities database (inv-isbn entities)
    @id = @get 'id'
    isbn = @get 'isbn'
    unless isbn?
      throw new Error "isbn entity doesn't have an isbn: #{@get('uri')}"

    @uri = @get('uri') or "isbn:#{isbn}"
    canonical = pathname = "/entity/#{@uri}"
    @findAPicture()

    if title = @get 'title'
      pathname += "/" + _.softEncodeURI(title)

    @set
      canonical: canonical
      pathname: pathname
      domain: 'isbn'
      # need to be set for inv-isbn entities
      uri: @uri

  findAPicture: ->
    pictures = @get 'pictures'
    if _.isEmpty pictures
      @_fetchPicture()
    else
      @set 'pictures', pictures.map(books_.uncurl)

  _fetchPicture: ->
    books_.getImage @uri
    .then (images)=> @set 'pictures', images.map(_.property('image'))
    .catch _.Error('findAPicture')

  getAuthorsString: ->
    str = @get 'authors'
      .map parseAuthor
      .join ', '

    _.log str, 'isbn author'
    return _.preq.resolve str


parseAuthor = (a)->
  switch a.type
    when 'wikidata_id' then a.label
    when 'string' then a.value
