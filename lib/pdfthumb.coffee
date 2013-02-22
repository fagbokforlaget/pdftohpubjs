require 'shelljs/global'
fs = require 'fs-extra'
im = require 'imagemagick'

class pdfToThumb
    # generating thumbnails from pdf file
    # new pdfToThumb(srcFile, destDir, page).execute(callback)
    # srcFile - path to pdf file
    # destDir - path to directory where generated thumbnail will be stored
    # page - page which is going to be used for generating thumb
    # callback - callback function

    constructor: (@file, @destDir, @page) ->
        @thumb = undefined
        fs.mkdirsSync("#{@destDir}")
        fs.mkdirsSync("#{@destDir}/tmp")

    execute: (callback) ->
        exec "pdftocairo -png -f #{@page} -l #{@page} #{@file} #{@destDir}/tmp/book", (code, output) =>
            switch code
                when 0 then return @parse(callback)
                when 1 then return callback(Error "Error opening a PDF file")
                when 3 then return callback(Error "Error related to PDF permissions")
                when 4 then return callback(Error "Error related to ICC profile")
                when 99 then return callback(Error "Other error")

    done: (srcName, callback) ->
        fs.removeSync "#{@destDir}/tmp/#{srcName}"
        fs.removeSync "#{@destDir}/tmp"
        callback(null)

    parse: (callback) ->
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
                width: 147
                height: 205

            im.resize options, (err, stdout, stderr) =>
                if err then throw err
                # fs.copy "#{@destDir}/__thumbs__/page#{@page}.png", "#{@destDir}/book.png" if @page is 1
                @done srcName, callback

exports.pdfToThumb = pdfToThumb