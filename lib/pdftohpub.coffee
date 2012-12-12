require 'shelljs/global'
pdftohtml = require 'pdftohtmljs'
async = require 'async'
fs = require 'fs-extra'
_ = require 'underscore'
HPUB = require('hpubjs')

DateHelper = require('./date_helper').DateHelper
pdfToThumb = require('./pdfthumb').pdfToThumb
pdfInfo = require('./pdfinfo').pdfInfo


class pdftohpub
    # pdf to hpub converter
    constructor: (@pdf, @destDir) ->
        @pages = undefined
        fs.mkdirsSync(@destDir)
        @hpub = @_setUpHpub()

        @importOptions = []

        @filenamePrefix = 'page-'
        @filenameSuffix = '.html'
        
        @

    addImportOptions: (options) ->
        # options (as Array) for importing from pdf
        @importOptions = _.union @importOptions, options
        @

    useDefaultImportOptions: ->
        # default options for pdftohtmljs
        @addImportOptions ['--space-as-offset 1', 
                        '--zoom 1.33', 
                        '--font-format woff', 
                        '--font-suffix .woff'
                    ]
        @

    _setUpHpub: ->
        # helper method for setting up an hpub writer
        meta =
            hpub: 1 
            author: []
            title: ""
            date: DateHelper.toString(new Date())
            url: ''
            contents: []

        writer = HPUB.Writer
        hpub = new writer @destDir
        hpub.addMeta meta
        return hpub
    
    generateThumb: (page, callback) ->
        # generate cover image
        # @hpub.meta.cover = new pdfToThumb(@pdf, @destDir).execute()
        if typeof page is "function"
            callback = page
            page = 1

        new pdfToThumb(@pdf, @destDir, page).execute ->
            callback()

    generatePage: (num, callback) ->
        # generate one page
        self = @
        transcoder = @_initializeTranscoder()
        transcoder.add_options(['-f '+ num, '-l ' + num])
        
        pageName = @_buildPageName(num)
        transcoder.add_options([pageName])
        
        transcoder.success ->
            self.hpub.addPage pageName
            callback.call(self, num)

        transcoder.error (error) ->
            console.log "error", error

        transcoder.progress (ret) ->
            console.log "progress", ret

        transcoder.convert()
        @

    _buildPageName: (num) ->
        # helper for building proper page file names
        zeros = ""
        if @pages > 1000
            if num < 10 then zeros = "000"
            if num >= 10 and num < 100 then zeros = "00"
            if num >= 100 and num < 1000 then zeros = "0"
        if @pages > 100
            if num < 10 then zeros = "00"
            if num >= 10 and num < 100 then zeros = "0"
        if @pages > 10
            if num < 10 then zeros = "0"

        "#{@filenamePrefix}#{zeros}#{num}#{@filenameSuffix}"

    _initializeTranscoder: ->
        # initialzie transcoder from pfd to html5
        # uses default options when no option is set
        transcoder = new pdftohtml(@pdf);
        if _.isEmpty @importOptions then @useDefaultImportOptions()
        transcoder.add_options(@importOptions)
        transcoder.add_options(['--dest-dir '+ @destDir])
        return transcoder
        
    generatePages: (startFrom, callback) ->
        # used for generating pages starting from startFrom page
        # after finish provided callback function is performed
        next = (num) =>
            if num < @pages then @generatePage(num + 1, next)
            else done()

        done = =>
            callback()

        series = []
        @getInfo()

        @generatePage startFrom, next


    buildBook: (thumbPage, callback) ->
        # generates cover and pages
        if typeof thumbPage is "function"
            callback = thumbPage
            thumbPage = 1

        @generateThumb thumbPage, =>
            @generatePages 1, callback


    listContent: (callback) ->
        fs.readdir @destDir, (err, list) =>
            for file in list
                @hpub.filelist.push file
                        
            callback(err)

    generateBook: (callback) ->
        self = @
        transcoder = @_initializeTranscoder()
        transcoder.add_options(["book"])

        transcoder.success ->
            callback.call(self)

        transcoder.error (error) ->
            console.log "error", error

        transcoder.progress (ret) ->
            console.log "progress", ret

        transcoder.convert()
        @

    buildBookWithSeparatedPages: (thumbPage, callback) ->
        # generates cover and pages
        if typeof thumbPage is "function"
            callback = thumbPage
            thumbPage = 1

        @generateThumb thumbPage, =>
            @generateBook  =>
                @listContent =>
                    callback()

    getInfo: ->
        # fetch basic info from PDF file
        # the most important thing is number of pages
        @pdfInfo = new pdfInfo(@pdf).execute().info
        @pages = parseInt(@pdfInfo.Pages, 10)

    finalize: (callback) ->
        # builds hpub and pack it into .hpub file
        @hpub.build (err) =>
            @hpub.pack @destDir, (size) ->
                callback(size)

exports.pdftohpub = pdftohpub