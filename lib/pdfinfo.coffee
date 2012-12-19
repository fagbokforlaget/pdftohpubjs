require 'shelljs/global'
S = require('string')

class PdfInfo
    # fetching information about pdf file (e.g. number of pages)
    # info = new PdfInfo(/path/to/pdf/file.pdf).execute()
    constructor: (@file) ->
        @info = {}
        @        

    execute: ->
        child = exec "pdfinfo #{@file}", {async: false, silent: true}
        switch child.code
            when 0 then @parse child.output
            when 1 then return Error "Error opening a PDF file"
            when 3 then return Error "Error related to PDF permissions"
            when 99 then return Error "Other error"
        @

    parse: (text) ->
        lines = text.match(/^.*([\n\r]+|$)/gm)
        for line in lines
            data = line.split(':')
            if data[0]
                @info[data[0]] = S(data[1]).trim().s
        @

exports.pdfInfo = PdfInfo