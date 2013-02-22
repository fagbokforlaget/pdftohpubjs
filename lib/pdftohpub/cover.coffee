fs = require 'fs-extra'
pdfToThumb = require('./pdfthumb').pdfToThumb

class Cover
  constructor: (@pdfFile, @hpubDir, @options) ->
    unless @options.coverThumb then @options.coverThumb = 1

  fetch: (callback) ->
    if fs.existsSync "#{@hpubDir}/#{@options.thumbFolder}/page#{@options.coverThumb}.png"
      fs.copy "#{@hpubDir}/#{@options.thumbFolder}/page#{@options.coverThumb}.png", "#{@hpubDir}/book.png", (err) ->
        callback err
    else
      @_generateCover callback

  _generateCover: (callback) ->
    new pdfToThumb(@pdfFile, "#{@hpubDir}", @options.coverThumb).execute (err) =>
      fs.copy "#{@hpubDir}/page#{@options.coverThumb}.png", "#{@hpubDir}/book.png", (err) =>
        fs.removeSync "#{@hpubDir}/page#{@options.coverThumb}.png"
        callback err

module.exports = Cover