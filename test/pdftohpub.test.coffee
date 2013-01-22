assert = require('assert')
fs = require 'fs-extra'
pdftohpub = require('../index.js')

describe 'pdftohpub', ->
  describe 'converter', ->

    it 'should report info about pdf', ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')

        converter.getInfo()
        assert.equal converter.pages, 4

    it 'should generate one page', (done) ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')

        converter.generatePage 1, (num) ->
            assert.equal num, 1
            assert.equal fs.existsSync('test/book/page-1.html'), true
            fs.removeSync 'test/book'
            done()

    it 'should generate pages', (done) ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')

        converter.generatePages 1, ->
            assert.equal fs.existsSync('test/book/page-1.html'), true
            assert.equal fs.existsSync('test/book/page-2.html'), true
            assert.equal fs.existsSync('test/book/page-3.html'), true
            assert.equal fs.existsSync('test/book/page-4.html'), true

            fs.removeSync 'test/book'
            done()

    it 'should build book', (done) ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')

        converter.buildBook ->
            assert.equal fs.existsSync('test/book/page-1.html'), true
            assert.equal fs.existsSync('test/book/book.png'), true

            fs.removeSync 'test/book'
            done()

    it 'should build book.hpub', (done) ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')

        converter.buildBook ->
            converter.finalize (err) ->
                assert.equal fs.existsSync('test/book.hpub'), true
                assert.equal fs.existsSync('test/book/book.json'), true

                fs.removeSync 'test/book'
                fs.removeSync 'test/book.hpub'
                done()

    it 'should generate one page with custom options', (done) ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')

        options = [
            '--space-as-offset 1', 
            '--zoom 2.33', 
            '--font-format woff', 
            '--font-suffix .woff',
            '--single-html 0'
        ]
        converter.addImportOptions(options)

        converter.generatePage 1, (num) ->
            assert.equal num, 1
            assert.equal fs.existsSync('test/book/base.css'), true            
            fs.removeSync 'test/book'
            done()
    
    it 'should generate new book format', (done) ->
        converter = new pdftohpub("test/sample.pdf", 'test/book')
        options = [
            '--space-as-offset 1', 
            '--zoom 2.33', 
            '--font-format woff', 
            '--font-suffix .woff',
            '--split-pages 1',
            '--css-filename book.css'
        ]
        converter.addImportOptions(options)
        converter.buildBookWithSeparatedPages () ->
            assert.equal converter.hpub.filelist.length, 10
            fs.removeSync 'test/book'
            done()

