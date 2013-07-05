HPUB = require('hpubjs')
Lister = require './lister'
moment = require 'moment'
_ = require 'underscore'

# this class has to be moved to hpubjs!!!
class Content
  constructor: (@list) ->
    
  exec: ->
    _.filter @list, (list) ->
      parts = list.split('.')
      ext = parts[parts.length - 1]

      if ext is "page" or ext is "html"
        return list

class Hpuber
  constructor: (@dir, mdata={}) ->
    meta =
      hpub: 1
      author: ['undefined']
      title: "undefined"
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
