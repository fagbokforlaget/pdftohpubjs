HPUB = require('hpubjs')
Lister = require './lister'
moment = require 'moment'
_ = require 'underscore'

# this class has to be moved to hpubjs!!!
class Content
  constructor: (@list) ->

  exec: ->
    filtered = _.filter @list, (list) ->
      regex = /page([0-9]+).html/.exec(list)
      return list if regex and regex[1]

    _.sortBy filtered, (page) ->
      regex = /page([0-9]+).html/.exec(page)
      if regex then return parseInt(regex[1], 10)
      else return 0

class Hpuber
  constructor: (@dir, mdata={}) ->
    meta =
      hpub: 1
      author: []
      title: undefined
      date: moment().format("YYYY-MM-DD")
      url: 'http://example.com/book.hpub'
      contents: []

    meta = _.extend meta, mdata

    writer = HPUB.Writer
    @hpub = new writer @dir
    @hpub.addMeta meta

  feed: (callback) ->
    new Lister(@dir).list (err, list) =>
      @hpub.filelist = list

      @hpub.meta.contents = _.union @hpub.meta.contents, new Content(list).exec()
      @hpub.meta.cover = "book.png" if list.indexOf("book.png") > 0
      callback null, @

  finalize: (callback) ->
    # builds hpub and pack it into .hpub file
    @hpub.build (err) =>
      @hpub.pack @dir, (size) ->
        callback(size)

  build: (callback) ->
    @hpub.build (err) =>
      callback err

module.exports = Hpuber
