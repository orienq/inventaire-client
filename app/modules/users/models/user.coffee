UserCommons = require './user_commons'
map_ = require 'modules/map/lib/map'

module.exports = UserCommons.extend
  isMainUser: false
  initialize: ->
    @setPathname()

  serializeData: ->
    attrs = @toJSON()
    relationStatus = attrs.status
    # converting the status into a boolean for templates
    attrs[relationStatus] = true
    # nonRelationGroupUser status have the same behavior as public users for views
    if relationStatus is 'nonRelationGroupUser'
      attrs.public = true
    attrs.inventoryLength = @inventoryLength()
    return attrs

  inventoryLength: ->
    if @itemsFetched then app.request 'inventory:user:length', @id

  distanceFromMainUser: ->
    unless app.user.has('position') and @has('position') then return null

    a = app.user.get 'position'
    b = @get 'position'
    distance = map_.distanceBetween a, b
    # Under 20km, return a ~100m precision to signal the fact that location
    # aren't precise to the meter or anything close to it
    # Above, return a ~1km precision
    precision = if distance > 20 then 0 else 1
    return Number(distance.toFixed(precision)).toLocaleString()
