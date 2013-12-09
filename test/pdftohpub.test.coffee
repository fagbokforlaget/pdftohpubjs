assert = require('assert')
fs = require 'fs-extra'
pdftohpub = require('../index.js')
_ = require 'underscore'

describe 'pdftohpub', ->
  describe 'converter', ->

    it 'should merge pdf options', ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.pdfOptions =
        'single-page': '1'
        'fit-width': '768'
        'zoom':''

      assert.equal converter.mergePdfOptions()['single-page'], '1'
      assert.equal converter.mergePdfOptions()['fit-width'], '768'
      assert.equal converter.mergePdfOptions()['zoom'], ''


    it "should escape on pdftohtmlEX error", (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.pdfOptions =
        'wrong': '1'

      converter.options =
        buildThumbs: true

      converter.convert (err, obj) ->
        assert.equal err, "pdf2htmlEX: unrecognized option '--wrong'\n"
        done()

    it 'should merge options', ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: null
        thumbSize:
          width: 10
          height: 20

      assert.equal converter.mergeOptions().buildThumbs, null
      assert.equal converter.mergeOptions().thumbSize.width, 10

    it 'should generate thumbs', (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: true
        coverThumb: false

      converter.generateThumbs (err) ->
        assert.equal fs.existsSync('test/book/__thumbs__/page1.png'), true
        fs.removeSync 'test/book'
        done()

    it "should generate thumbs from page A to page B", (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: true
        coverThumb: false
        pageStart: 2
        pageEnd: 3

      converter.generateThumbs (err) ->
        assert.equal fs.existsSync('test/book/__thumbs__/page1.png'), false
        assert.equal fs.existsSync('test/book/__thumbs__/page2.png'), true
        assert.equal fs.existsSync('test/book/__thumbs__/page3.png'), true
        fs.removeSync 'test/book'
        done()

    it 'should copy cover page', (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: true

      converter.generateThumbs (err) ->
        assert.equal fs.existsSync('test/book/__thumbs__/page1.png'), true
        assert.equal fs.existsSync('test/book/book.png'), true
        fs.removeSync 'test/book'
        done()

    it 'should create cover page', (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: false

      converter.getCover (err) ->
        assert.equal fs.existsSync('test/book/book.png'), true
        fs.removeSync 'test/book'
        done()

    it 'should convert pdf', (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: true
      converter.progress (progress) ->
        assert.equal (progress <= 100 and progress >= 0), true

      converter.convert (err, obj) ->
        assert.equal fs.existsSync('test/book/book.png'), true
        assert.equal fs.existsSync('test/book/book.css'), true
        assert.equal fs.existsSync('test/book/page1.html'), true
        assert.equal _.isArray(obj.hpub.filelist), true
        assert obj.hpub.filelist.length > 0, true
        fs.removeSync 'test/book'
        done()

    it 'should build hpub', (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: true
        buildHpub: true

      converter.pdfOptions =
        'zoom':''
        'fit-height':'1024'
        'fit-width':'768'


      converter.progress (progress) ->
        assert.equal (progress <= 100 and progress >= 0), true

      converter.convert (err, obj) ->
        assert.equal fs.existsSync('test/book/book.png'), true
        assert.equal fs.existsSync('test/book/book.css'), true
        assert.equal fs.existsSync('test/book/page1.html'), true
        assert.equal fs.existsSync('test/book/book.json'), true

        fs.readFile 'test/book/book.json', (err, file) ->
          data = JSON.parse(file)
          fs.removeSync 'test/book'
          done()

    it "should be able to add metadata to hpub", (done) ->
      converter = new pdftohpub("test/sample.pdf", 'test/book')

      converter.options =
        buildThumbs: true
        buildHpub: true

      converter.addMetadata
        author: ["author"]
        title: "Title"

      converter.progress (progress) ->
        assert.equal (progress <= 100 and progress >= 0), true

      converter.convert (err, obj) ->
        assert.equal fs.existsSync('test/book/book.json'), true
        assert.equal obj.hpub.meta.author[0], "author"
        assert.equal obj.hpub.meta.title, "Title"
        assert.equal obj.hpub.meta.cover, "book.png"

        fs.removeSync 'test/book'
        done()
