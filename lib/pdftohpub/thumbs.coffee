async = require 'async'
pdfinfo = require('pdfinfojs')

pdfToThumb = require('./pdfthumb').pdfToThumb
Cover = require './cover'

class Thumbs
  constructor: (@pdfFile, @hpubDir, @options, @progress) ->

  setLogger: (@logger) ->
    @

  exec: (callback) ->
    if @options.buildThumbs
      @options.pageEnd = @getInfo() unless @options.pageEnd
      mySeries = [@options.pageStart..@options.pageEnd]

      async.forEachSeries mySeries, (page, next) =>
        @progress() if @progress
        @logger({title: "Generating thumbnails", data: "page#{page}.png"}) if @logger
        new pdfToThumb(@pdfFile, "#{@hpubDir}/#{@options.thumbFolder}", page, @options.thumb).execute (err) =>
          next()
      , (err) =>
        if @options.coverThumb
          new Cover(@pdfFile, @hpubDir, @options).fetch (err) ->
            callback err
        else
          callback err
    else
      new Cover(@pdfFile, @hpubDir, @options).fetch (err) ->
        callback err

  getInfo: ->
    pinfo = new pdfinfo(@pdfFile)
    ret = pinfo.getInfoSync()
    ret.pages

module.exports = Thumbs
