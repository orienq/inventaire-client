module.exports = (_)->
  idGenerator: (length, lettersOnly)->
    text = ''
    possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    possible += '0123456789'  unless lettersOnly
    i = 0
    while i < length
      text += possible.charAt _.random(possible.length - 1)
      i++
    return text

  buildPath: (pathname, queryObj, escape)->
    queryObj = @removeUndefined(queryObj)
    if queryObj? and not _.isEmpty queryObj
      queryString = ''
      for k,v of queryObj
        v = @dropSpecialCharacters(v)  if escape
        queryString += "&#{k}=#{v}"
      return pathname + '?' + queryString[1..-1]
    else pathname

  parseQuery: (queryString)->
    query = {}
    if queryString?
      queryString
      .replace /^\?/, ''
      .split '&'
      .forEach (param)->
        pairs = param.split '='
        if pairs[0]?.length > 0 and pairs[1]?
          query[pairs[0]] = _.softDecodeURI pairs[1]
    return query

  softEncodeURI: (str)->
    _.typeString str
    .replace /(\s|')/g, '_'
    .replace /\?/g, ''

  softDecodeURI: (str)->
    _.typeString str
    .replace /_/g,' '

  removeUndefined: (obj)->
    newObj = {}
    for k,v of obj
      if v? then newObj[k] = v
      else console.warn "#{k}:#{v} omitted"
    return newObj

  dropSpecialCharacters : (str)->
    str
    .replace /\s+/g, ' '
    .replace /(\?|\:)/g, ''

  isUrl: (str)->
    # not perfect, just roughly filtering
    # accepts url delegating protocol choice to the browser with only '//'
    pattern = new RegExp('^((https?:|)\\/\\/)?(([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}')
    return pattern.test(str)

  isDataUrl: (str)-> /^data:image/.test str

  isHostedPicture: (str)-> /img(loc)?.inventaire.io\/\w{22}.jpg$/.test str

  pickToArray: (obj, props...)->
    if _.isArray(props[0]) then props = props[0]
    _.typeArray props
    pickObj = _.pick(obj, props)
    # returns an undefined array element when prop is undefined
    return props.map (prop)-> pickObj[prop]

  mergeArrays: _.union

  haveAMatch: (arrays...)-> _.intersection.apply(_, arrays).length > 0
