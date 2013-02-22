pdftohtml = require 'pdftohtmljs'
_ = require 'underscore'

class Transcoder
  constructor: (@file, @options) ->
    @transcoder = new pdftohtml(@file)
    @transcoder.add_options(@importOptions())
    @transcoder.add_options(["page"])

  importOptions: ->
    _.map @options, (val, key) ->
      "--#{key} #{val}"

  get: ->
    @transcoder

module.exports = Transcoder