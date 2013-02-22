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
var converter = new pdftohpub("test/sample.pdf", 'test/book');

converter.options = {
  buildThumbs: true
};

converter.progress(function(progress) {
  console.log("progress", progress)
});

converter.convert(function(err, obj) {
  console.log(obj);
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
