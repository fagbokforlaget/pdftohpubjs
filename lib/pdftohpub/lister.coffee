fs = require 'fs-extra'
_ = require 'underscore'

class Lister
  constructor: (@startDir) ->
    @

  list: (callback) ->
    res = []
    @_walk @startDir, (err, result) =>
      list = _.sortBy result, (name) ->
        reg = /page([0-9]+)/.exec(name)
        if reg then return Number(reg[1]) else return name
      callback(err, list)

  _walk: (dir, done) ->
    # recursive search in directory
    # http://stackoverflow.com/a/5827895
    self = @
    results = []
    fs.readdir dir, (err, list) ->
      return done(err) if err

      pending = list.length
      return done(null, results) unless pending

      list.forEach (file) ->
        file = "#{dir}/#{file}"
        fs.stat file, (err, stat) ->
          if stat and stat.isDirectory()
            self._walk file, (err, res) ->
              results = results.concat res
              done null, results unless --pending
          else
            results.push file.replace(self.startDir + "/", '')
            done null, results unless --pending

module.exports = Lister