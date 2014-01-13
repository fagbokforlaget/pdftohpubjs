require 'shelljs/global'
fs = require 'fs-extra'
im = require 'imagemagick'
_ = require 'underscore'

class pdfToThumb
    # generating thumbnails from pdf file
    # new pdfToThumb(srcFile, destDir, page).execute(callback)
    # srcFile - path to pdf file
    # destDir - path to directory where generated thumbnail will be stored
    # page - page which is going to be used for generating thumb
    # callback - callback function

    constructor: (@file, @destDir, @page, @options={}) ->
        @thumb = undefined
        fs.mkdirsSync("#{@destDir}")
        fs.mkdirsSync("#{@destDir}/tmp")

        @defaults =
            width: 147
            height: 205

    execute: (callback) ->
        exec "pdftocairo -png -cropbox -f #{@page} -l #{@page} #{@file} #{@destDir}/tmp/book", (code, output) =>
            switch code
                when 0 then return @parse(callback)
                when 1 then return callback(Error "Error opening a PDF file")
                when 3 then return callback(Error "Error related to PDF permissions")
                when 4 then return callback(Error "Error related to ICC profile")
                when 99 then return callback(Error "Other error")

    done: (err, srcName, callback) ->
        # fs.removeSync "#{@destDir}/tmp/#{srcName}"
        fs.removeSync "#{@destDir}/tmp"
        callback(err)

    parse: (callback) ->
        @options = _.extend @defaults, @options

        fs.readdir "#{@destDir}/tmp", (err, files) =>
            if err then throw err

            srcName = "book-#{@page}.png"
            for file in files
                filenameArr = file.split('.')
                if filenameArr[filenameArr.length - 1] is "png" and filenameArr[0].substr(0, 5) is "book-"
                    srcName = file

            options =
                srcPath: "#{@destDir}/tmp/#{srcName}"
                dstPath: "#{@destDir}/page#{@page}.png"

            @options = _.extend @options, options

            im.resize @options, (err, stdout, stderr) =>
                if err then @done(err)
                @done null, srcName, callback

exports.pdfToThumb = pdfToThumb
