require 'shelljs/global'
S = require('string')

class PdfInfo
    constructor: (@file) ->
        @info = {}
        @        

    execute: ->
        child = exec "pdfinfo #{@file}", {async: false, silent: true}
        switch child.code
            when 0 then @parse child.output
            when 1 then return throw new Error "Error opening a PDF file"
            when 3 then return throw new Error "Error related to PDF permissions"
            when 99 then return throw new Error "Other error"
        @

    parse: (text) ->
        lines = text.match(/^.*([\n\r]+|$)/gm)
        for line in lines
            data = line.split(':')
            if data[0]
                @info[data[0]] = S(data[1]).trim().s
        @

exports.pdfInfo = PdfInfo