HPUB = require('hpubjs')
Lister = require './lister'
moment = require 'moment'

class Hpuber
  constructor: (@dir) ->
    meta =
      hpub: 1 
      author: []
      title: ""
      date: moment().format("YYYY-MM-DD")
      url: ''
      contents: []

    writer = HPUB.Writer
    @hpub = new writer @dir
    @hpub.addMeta meta

  feed: (callback) ->
    new Lister(@dir).list (err, list) =>
      @hpub.filelist = list
      callback null, @hpub

  finalize: (callback) ->
    # builds hpub and pack it into .hpub file
    @hpub.build (err) =>
      @hpub.pack @dir, (size) ->
        callback(size)

module.exports = Hpuber