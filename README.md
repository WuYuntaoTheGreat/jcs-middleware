jcs-middleware
==============

Jade, CoffeeScript, Stylus middleware for Express.js

Installation
============

    npm install jcs-middleware

Usage
=====

## In Express app.js

    app.use('/', require('jsc-middleware')(options));

## Options:
 
    // Global options:
     'debug'         Output debugging information.
     'compress'      Uglify the output.
     'staticRoot'    The root directory of the static files.

    // Coffee-script options:
     'coffeeSrc'     Source directory used to find .coffee files.
     'coffeeDst'     Destination directory where the .js files are stored.
     'bare'          Compile JavaScript without the top-level function safty wrapper.
     'encodeSrc'     Encode CoffeeScript source file as base64 comment in compiled JavaScript.

    // Stylus options:
     'stylusSrc'     Source directory used to find .styl files.
     'stylusDst'     Destination directory where the .css files are stored.

    // Jade options:
     'jadeSrc'       Source directory used to find .jade files.
     'jadeDst'       Destination directory where the .js files are stored.
     'jadeStatics'   Hash map used to generate jade pages.


## File Path

