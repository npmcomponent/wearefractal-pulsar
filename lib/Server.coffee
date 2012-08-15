Channel = require './Channel'

module.exports = (opt) ->
  out =
    options:
      namespace: 'Pulsar'
      resource: 'default'

    start: ->
      @channels = {}

    channel: (name) ->
      @channels[name] ?= new Channel name

    inbound: (socket, msg, done) ->
      try
        done JSON.parse msg
      catch err
        @error socket, err

    outbound: (socket, msg, done) ->
      try
        done JSON.stringify msg
      catch err
        @error socket, err

    validate: (socket, msg, done) ->
      return done false unless typeof msg is 'object'
      return done false unless typeof msg.type is 'string'
      switch msg.type
        when 'emit'
          return done false unless typeof msg.channel is 'string'
          return done false unless typeof @channels[msg.channel]?
          return done false unless typeof msg.event is 'string'
          return done false unless Array.isArray msg.args
        when 'join'
          return done false unless typeof msg.channel is 'string'
          return done false unless typeof @channels[msg.channel]?
        when 'unjoin'
          return done false unless typeof msg.channel is 'string'
          return done false unless typeof @channels[msg.channel]?
        else
          return done false
      return done true

    invalid: (socket, msg) -> socket.close()

    message: (socket, msg) ->
      chan = @channels[msg.channel]
      switch msg.type
        when'emit'
          chan.realEmit msg.event, msg.args...
        when 'join'
          # TODO: Pass an eventemitter instead of socket
          chan.listeners.push socket
          chan.realEmit 'join', socket
          socket.write
            type: 'joined'
            channel: msg.channel
        when 'unjoin'
          # TODO: remove socket from chan.listeners
          chan.realEmit 'unjoin', socket

  out.options[k]=v for k,v of opt
  return out