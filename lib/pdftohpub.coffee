fs = require 'fs-extra'
_ = require 'underscore'
pdfinfo = require 'pdfinfojs'

Transcoder = require './pdftohpub/transcoder'
Cover = require './pdftohpub/cover'
Thumbs = require './pdftohpub/thumbs'
Hpuber = require './pdftohpub/hpuber'

class PdfToHpub
  constructor: (@pdfFile, @hpubDir) ->
    @pdfOptions = {}

    @pdfDefaults =
      'embed': 'cfijo'
      'split-pages': '1'
      'space-as-offset': '0'
      'font-format': 'woff'
      'dest-dir': @hpubDir
      'css-filename': 'book.css'
      'decompose-ligature': '1'
      'page-filename': 'page%d.html'

    @options = {}

    @defaults =
      buildHpub: false
      cleanDir: false
      buildThumbs: true
      coverThumb: 1
      thumb:
        width: 147
        height: 205
      pageStart: 1
      pageEnd: undefined
      thumbFolder: "__thumbs__"

    @progressCB = undefined
    @loggerCB = undefined
    @progressVal = 0
    @unit = 0
    @metadata = {}

    fs.mkdirsSync(@hpubDir)

  triggerProgress: ->
    if @progress and typeof @progress is "function"
      @progress @progressState

  generateThumbs: (callback) ->
    @unit = @unit + @pagesCount if @options.buildThumbs
    @mergeOptions()
    new Thumbs(@pdfFile, @hpubDir, @options, @updateProgress).setLogger(@updateLogger).exec (err) ->
      callback(err)

  getCover: (callback) ->
    @mergeOptions()
    new Cover(@pdfFile, @hpubDir, @options).fetch (err) =>

      callback(err)

  convertPdf: (callback) ->
    self = @

    transcoder = new Transcoder(@pdfFile, @mergePdfOptions()).get()

    transcoder.success ->
      callback.call(self)

    transcoder.error (error) ->
      callback.call(self, error)

    transcoder.progress (ret) =>
      data = self.pdfDefaults['page-filename'].replace(/\%d/, ret.current)
      self.updateLogger({title: "Converting pdf page", data: data})
      self.updateProgress()

    transcoder.convert()

  convert: (callback) ->
    # @pagesCount = @getInfo()
    @getInfo (err, pagesCount) =>
      if err then return callback(err, @)
      @pagesCount = pagesCount
      @mergeOptions()
      @unit = @unit + pagesCount

      @generateThumbs (err) =>
        if err then return callback err
        @updateLogger({title: "Converting pdf", data: null})
        @convertPdf (err) =>
          if err then return callback err
          @updateLogger({title: "Creating hpub structure"})
          new Hpuber(@hpubDir, @metadata).feed (err, hpub) =>
            @hpub = hpub.hpub
            if @options.buildHpub
              @updateLogger({title: "Building hpub structure"})
              hpub.build (err) =>
                @progressCB(100)
                callback err, @
            else
              @progressCB(100)
              callback err, @

  addMetadata: (metadata) ->
    @metadata = _.extend @metadata, metadata

  mergeOptions: ->
    @options = _.extend @defaults, @options

  mergePdfOptions: ->
    @pdfOptions = _.extend @pdfDefaults, @pdfOptions
    @pdfOptions

  progress: (callback) ->
    @progressCB = callback

  logger: (callback) ->
    @loggerCB = callback

  updateProgress: =>
    @unit = 1.00/(@unit+1) if @unit > 1

    @progressVal++
    if @progressCB and typeof @progressCB is "function"
      @progressCB(Math.floor @progressVal*@unit*100)

  updateLogger: (logs) =>
    if @loggerCB and typeof @loggerCB is "function"
      @loggerCB logs

  getInfo: (callback) ->
    pinfo = new pdfinfo(@pdfFile)
    try
      ret = pinfo.getInfoSync()
      callback(null, parseInt ret.pages, 10)
    catch error
      callback(error)

module.exports = PdfToHpub
