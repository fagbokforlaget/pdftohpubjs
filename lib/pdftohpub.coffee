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
      'single-html': '0'
      'split-pages': '1'
      'space-as-offset': '1'
      'zoom': 1.3333
      'font-suffix': '.woff'
      'dest-dir': @hpubDir
      'css-filename': 'book.css'
      'decompose-ligature': '1'

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
    @progressVal = 0
    @unit = 0
    @metadata = {}

    fs.mkdirsSync(@hpubDir)
    @pagesCount = @getInfo()

  triggerProgress: ->
    if @progress and typeof @progress is "function"
      @progress @progressState

  generateThumbs: (callback) ->
    @unit = @unit + @pagesCount if @options.buildThumbs
    @mergeOptions()
    new Thumbs(@pdfFile, @hpubDir, @options, @updateProgress).exec (err) ->
      callback(err)

  getCover: (callback) ->
    @mergeOptions()
    new Cover(@pdfFile, @hpubDir, @options).fetch (err) ->
      callback(err)

  convertPdf: (callback) ->
    self = @   

    transcoder = new Transcoder(@pdfFile, @mergePdfOptions()).get()    

    transcoder.success ->
      callback.call(self)

    transcoder.error (error) ->
      console.log "error", error

    transcoder.progress (ret) =>
      self.updateProgress()

    transcoder.convert()  
    
  convert: (callback) ->
    @mergeOptions()
    @unit = @unit + @pagesCount

    @generateThumbs (err) =>
      if err then return callback err
      @convertPdf (err) =>
        if err then return callback err
        new Hpuber(@hpubDir, @metadata).feed (err, hpub) =>
          @hpub = hpub.hpub
          if @options.buildHpub
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

  progress: (callback) ->
    @progressCB = callback

  updateProgress: =>
    @unit = 1.00/(@unit+1) if @unit > 1

    @progressVal++
    if @progressCB and typeof @progressCB is "function"
      @progressCB(Math.floor @progressVal*@unit*100)

  getInfo: ->
    pinfo = new pdfinfo(@pdfFile)
    ret = pinfo.getSync()
    parseInt ret.pages, 10

module.exports = PdfToHpub