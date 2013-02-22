async = require 'async'
pdfinfo = require('pdfinfojs')

pdfToThumb = require('./pdfthumb').pdfToThumb
Cover = require './cover'

class Thumbs
  constructor: (@pdfFile, @hpubDir, @options, @progress) ->

  exec: (callback) ->
    if @options.buildThumbs
      @options.pageEnd = @getInfo() unless @options.pageEnd
      mySeries = [@options.pageStart..@options.pageEnd]

      async.forEachSeries mySeries, (page, next) =>
        @progress() if @progress
        new pdfToThumb(@pdfFile, "#{@hpubDir}/#{@options.thumbFolder}", page).execute (err) =>
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
    ret = pinfo.getSync()
    ret.pages

module.exports = Thumbs