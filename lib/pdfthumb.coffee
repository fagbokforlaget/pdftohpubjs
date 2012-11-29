require 'shelljs/global'
fs = require 'fs-extra'
im = require 'imagemagick'

class pdfToThumb
    constructor: (@file, @destDir, @page) ->
        @thumb = undefined

    execute: (callback) ->
        child = exec "pdftocairo -png -f #{@page} -l #{@page} #{@file} #{@destDir}/book", {async: false}
        switch child.code
            when 0 then @parse(callback)
            when 1 then return throw new Error "Error opening a PDF file"
            when 3 then return throw new Error "Error related to PDF permissions"
            when 4 then return throw new Error "Error related to ICC profile"
            when 99 then return throw new Error "Other error"
        
        return "book.png"

    done: (callback) ->
        fs.removeSync "#{@destDir}/book-#{@page}.png"
        callback()

    parse: (callback) ->
        options =
            srcPath: "#{@destDir}/book-#{@page}.png"
            dstPath: "#{@destDir}/book.png"
            width: 147
            height: 205

        im.resize options, (err, stdout, stderr) =>
            if err then throw err
            @done callback

exports.pdfToThumb = pdfToThumb