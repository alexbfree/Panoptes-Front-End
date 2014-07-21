dispatcher = require './dispatcher'

class Store
  path: '/'
  handers: null

  _items: null
  _signals: null

  constructor: (options = {}) ->
    for property, value of options
      @[property] = value

    @_items ?= []
    @_signals ?= []

    dispatcher.register this

  on: (signal, [context]..., handler) ->
    @_signals.push {signal, context, handler}

  off: (signal, [context]..., handler) ->
    for {a, c, h}, i in @_signals when a is signal and c is context and h is handler
      index = i
    @_signals.splice index, 1

  emit: (signal, payload) ->
    for {signal: a, context, handler} in @_signals when a is signal
      if typeof handler is 'string'
        handler = context[handler]
      handler.call context, payload

  set: (property, value) ->
    object = this
    segments = property.split '.'

    until segments.length is 1
      segment = segments.shift()
      object = object[segment]

    object[segments[0]] = value

    @emit 'change'

  add: (items...) ->
    @_items.push items...
    @emit 'change'
    items

  remove: (items...) ->
    for item in items
      index = @_items.indexOf item
      unless index is -1
        @_items.splice index, 1
    items

  filter: (params) ->
    if typeof params is 'function'
      @_items.filter arguments...
    else if typeof params is 'string'
      item for item in @_items when item.id is params
    else
      matches = []
      for item in @_items
        okay = true
        for key, value of params
          unless item[key] is value
            okay = false
            break
        if okay
          matches.push item
      matches

  find: ->
    @filter(arguments...)[0]

window.Store = Store
module.exports = Store