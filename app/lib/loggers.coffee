# allow to pass a csle object so that we can pass whatever we want in tests
module.exports = (_, csle)->
  csle or= window.console

  log = (obj, label, stack)->
    # customizing console.log
    # unfortunatly, it makes the console loose the trace
    # of the real line and file the _.log function was called from
    # the trade-off might not be worthing it...
    if _.isString obj
      if label? then obj.logIt(label)
      else csle.log obj
    else
      csle.log "===== #{label} =====" if label?
      csle.log obj
      csle.log "-----" if label?

    # log a stack trace if stack option is true
    if stack
      # prerender error object doesnt seem to have a stack, thus the stack?
      csle.log "#{label} stack", new Error('fake error').stack?.split("\n")

    return obj

  error = (err, label)->
    if err?.status?
      # log http errors
      if err?.responseText? then label = "#{err.responseText} (#{label})"
      switch err.status
        when 401 then return csle.warn '401', label
        when 404 then return csle.warn '404', label
        # else it will be treated as other errors

    unless err?.stack?
      label or= 'empty error'
      newErr = new Error(label)
      report = [err, newErr.message, newErr.stack?.split('\n')]
    else
      report = [err.message or err, err.stack?.split('\n')]

    if err?.context? then report.push err.context

    window.reportErr {error: report}
    csle.error.apply csle, report

  # providing a custom warn as it might be used
  # by methods shared with the server
  warn = (args...)->
    csle.warn '/!\\'
    loggers.log.apply null, args
    return

  # inspection utils to log a label once a function is called
  spy = (res, label)->
    console.log label
    return res


  partialLoggers =
    Log: (label)-> _.partial log, _, label
    Error: (label)-> _.partial error, _, label
    Warn: (label)-> _.partial warn, _, label
    Spy: (label)-> _.partial spy, _, label
    ErrorRethrow: (label)->
      return fn = (err)->
        error err, label
        throw err

  loggers =
    log: log
    error: error
    warn: warn
    spy: spy


    logAllEvents: (obj, prefix='logAllEvents')->
      obj.on 'all', (event)->
        csle.log "[#{prefix}:#{event}]"
        csle.log arguments
        csle.log '---'

    logArgs: (args)->
      csle.log "[arguments]"
      csle.log args
      csle.log '---'

    logServer: (obj, label)->
      report = {obj: obj, label: label}
      $.post app.API.test, report
      return obj

  String::logIt = (label)->
    csle.log "[#{label}] #{@toString()}"
    return @toString()

  proxied =
    trace: csle.trace.bind(csle)
    time: csle.time.bind(csle)
    timeEnd: csle.timeEnd.bind(csle)

  return _.extend loggers, partialLoggers, proxied
