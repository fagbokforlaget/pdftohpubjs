## pdftohpubjs - PDF to hpub converter



### Installation

via npm:

```

$ npm install pdftohpubjs

```

It is important to install `imagemagick` for generating thumbnails.

```

sudo apt-get install imagemagick

```

### Usage

```
var pdftohpub = require('pdftohpubjs');

var converter = new pdftohpub("test/sample1.pdf", 'test/book');

var generateThumbFromPage = 2;

// optionally, you can add options for exporting pdf to html5 files
var options = [
            '--space-as-offset 1', 
            '--zoom 2.33', 
            '--font-format woff', 
            '--font-suffix .woff',
            '--single-html 0'
        ]
converter.addImportOptions(options);

converter.buildBook(generateThumbFromPage, function() {
    converter.finalize(function(err){
        // the book.hpub is build by now!
    });
});
   

```

### Tests

```

$ npm test

```

Coverage (Make sure you have installed jscoverage (it's easy `sudo aptitude install jscoverage` or `brew jscoverage`)

```

$ npm test-cov

```
