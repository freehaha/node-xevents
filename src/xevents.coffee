debug = require('debug')("xevents")
x11 = require('x11')
x11prop = require('x11-prop')
get_prop = x11prop.get_property
async = require('async')
EventEmitter = require('events').EventEmitter

xevents = new EventEmitter()
x11.createClient (err, dp)->
  if err
    console.error "error creating client", err
    return
  X = dp.client
  root = dp.screen[0].root
  X.ChangeWindowAttributes(
    root,
    {
      eventMask: x11.eventMask.PropertyChange
    }
  )
  X.on 'event', (ev)->
    return unless ev.name is 'PropertyNotify'
    async.waterfall [
      (cb)-> X.GetAtomName ev.atom, cb
      (name, cb)-> get_prop X, root, '_NET_ACTIVE_WINDOW', 'WINDOW', cb
    ], (err, wins)->
      if err
        debug("")
        console.error err
        return
      async.each wins, (w, cb)->
        return cb(null) if w == 0
        async.parallel {
          title: (cb)->
            get_prop X, w, '_NET_WM_NAME', 'UTF8_STRING', (err, title)->
              cb(err, title[0])
          cls: (cb)->
            get_prop X, w, 'WM_CLASS', 'STRING', (err, cls)->
              ret = []
              for c in cls
                ret.push c.toString('utf8')
              cb(err, ret)

        }, (err, results)->
          xevents.emit 'active', {
            title: results["title"]
            class: results["cls"]
          }

module.exports = xevents
