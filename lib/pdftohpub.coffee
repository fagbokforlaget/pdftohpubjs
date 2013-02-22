require 'shelljs/global'
pdftohtml = require 'pdftohtmljs'
async = require 'async'
fs = require 'fs-extra'
_ = require 'underscore'
HPUB = require('hpubjs')
pdfinfo = require('pdfinfojs')

DateHelper = require('./date_helper').DateHelper
pdfToThumb = require('./pdfthumb').pdfToThumb
pdfInfo = require('./pdfinfo').pdfInfo

class Transcoder
  constructor: (@file, @options) ->
    @transcoder = new pdftohtml(@file)
    @transcoder.add_options(@importOptions())
    # @transcoder.add_options(['--dest-dir '+ @hpubDir])
    @transcoder.add_options(["page"])

  importOptions: ->
    _.map @options, (val, key) ->
      "--#{key} #{val}"

  get: ->
    @transcoder

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

class Lister
  constructor: (@startDir) ->
    @

  list: (callback) ->
    res = []
    @_walk @startDir, (err, result) =>
      list = _.sortBy result, (name) ->
        reg = /page([0-9]+)/.exec(name)
        if reg then return Number(reg[1]) else return name
      callback(err, list)

  _walk: (dir, done) ->
    # recursive search in directory
    # http://stackoverflow.com/a/5827895
    self = @
    results = []
    fs.readdir dir, (err, list) ->
      return done(err) if err

      pending = list.length
      return done(null, results) unless pending

      list.forEach (file) ->
        file = "#{dir}/#{file}"
        fs.stat file, (err, stat) ->
          if stat and stat.isDirectory()
            self._walk file, (err, res) ->
              results = results.concat res
              done null, results unless --pending
          else
            results.push file.replace(self.startDir + "/", '')
            done null, results unless --pending

class Hpuber
  constructor: (@dir) ->
    meta =
      hpub: 1 
      author: []
      title: ""
      date: DateHelper.toString(new Date())
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

    @options = {}

    @defaults =
      buildThumbs: true
      coverThumb: 1
      thumbSize:
        width: 147
        height: 205
      pageStart: 1
      pageEnd: undefined
      thumbFolder: "__thumbs__"

    @progressCB = undefined
    @progressVal = 0
    @unit = 0

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
        new Hpuber(@hpubDir).feed (err, hpub) =>
          @progressCB(100)
          @hpub = hpub
          callback null, @

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

exports.pdftohpub = PdfToHpub