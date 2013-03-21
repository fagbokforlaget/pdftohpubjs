pdftohtml = require 'pdftohtmljs'
_ = require 'underscore'

class Transcoder
  constructor: (@file, @options) ->
    @transcoder = new pdftohtml(@file)
    @transcoder.add_options(@importOptions())
    @transcoder.add_options(["page"])

  # It omits null or empty string values
  importOptions: ->
    _(@options).
    chain().
    map( (val, key) ->
      if typeof val == 'string' and val.length
        "--#{key} #{val}"
    ).
    reject( (val) ->
      return val == undefined
    ).
    value()

  get: ->
    @transcoder

module.exports = Transcoder
