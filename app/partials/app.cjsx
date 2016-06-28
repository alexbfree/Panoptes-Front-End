React = require 'react'
auth = require 'panoptes-client/lib/auth'
IOStatus = require './io-status'
AppLayout = require('../layout').default
GeordiLogger = require '../lib/geordi-logger'
{generateSessionID} = require '../lib/session'

PanoptesApp = React.createClass
  geordiLogger: null # Maintains project and subject context for the Geordi client

  childContextTypes:
    user: React.PropTypes.object
    updateUser: React.PropTypes.func
    geordi: React.PropTypes.object

  getChildContext: ->
    user: @state.user
    updateUser: @updateUser
    geordi: @geordiLogger

  getEnv: ->
    reg = /\W?env=(\w+)/
    browser_env = window?.location?.search?.match(reg)
    @state?.env || browser_env?[1] || 'staging'

  getInitialState: ->
    user: null
    env: @getEnv()
    initialLoadComplete: false

  updateUser: (user) ->
    @setState user: user

  componentDidMount: ->
    console.log "app-componentDidMount: env=#{@state?.env}"
    auth.listen 'change', @handleAuthChange
    generateSessionID()
    @handleAuthChange()

  componentWillUnmount: ->
    auth.stopListening 'change', @handleAuthChange

  componentWillUpdate: (nextProps, nextState) ->
    console.log "app-componentWillUpdate: env=#{nextState.env}"
    @geordiLogger = @geordiLogger || new GeordiLogger nextState

  handleAuthChange: ->
    auth.checkCurrent().then (user) =>
      @setState
        user: user
        initialLoadComplete: true

  render: ->
    <div className="panoptes-main">
      <IOStatus />
      {if @state.initialLoadComplete
        console.log "app-initialLoadComplete: env=#{@state?.env}"
        <AppLayout user={@state.user}>
          {React.cloneElement @props.children, user: @state.user}
        </AppLayout>}
    </div>

module.exports = PanoptesApp
