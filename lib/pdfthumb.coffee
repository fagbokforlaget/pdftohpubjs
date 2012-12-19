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

    execute: (callback) ->
        child = exec "pdftocairo -png -f #{@page} -l #{@page} #{@file} #{@destDir}/book", {async: false}
        switch child.code
            when 0 then @parse(callback)
            when 1 then return callback(Error "Error opening a PDF file")
            when 3 then return callback(Error "Error related to PDF permissions")
            when 4 then return callback(Error "Error related to ICC profile")
            when 99 then return callback(Error "Other error")

    done: (srcName, callback) ->
        fs.removeSync "#{@destDir}/#{srcName}"
        callback(null)

    parse: (callback) ->
        fs.readdir @destDir, (err, files) =>
            if err then throw err

            srcName = "book-#{@page}.png"
            for file in files
                filenameArr = file.split('.')
                if filenameArr[filenameArr.length - 1] is "png" and filenameArr[0].substr(0, 5) is "book-"
                    srcName = file

            options =
                srcPath: "#{@destDir}/#{srcName}"
                dstPath: "#{@destDir}/book.png"
                width: 147
                height: 205

            im.resize options, (err, stdout, stderr) =>
                if err then throw err
                @done srcName, callback

exports.pdfToThumb = pdfToThumb