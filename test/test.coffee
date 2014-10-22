#!
# jcs-middleware Copyright(c) 2014 Wu Yuntao
# https://github.com/WuYuntaoTheGreat/jcs-middleware
# Released under the MIT License.
# vim: set et ai ts=4 sw=4 cc=100 nu:
#

logger  = require("nice-logger").logger
assert  = require "assert"
fs      = require "fs"
path    = require "path"
mkdirp  = require "mkdirp"
url     = require "url"
rmdir   = require "rimraf"

JcsConstructor = require "../index"

staticRoot = path.join __dirname, "public"
sourceRoot = path.join __dirname, "views"

# Change the file timestamp.
touch = (f, d) ->
    d = d || new Date
    fs.utimesSync f, d, d

mockReq = (url, method) ->
    method = method || 'GET'
    return
        url: url
        method: method


describe "The test for jcs middleware", ->
    beforeEach (done)->
        logger.info "Delete & recreate static root..."
        rmdir staticRoot, (err)->
            logger.error err
            throw err

        mkdirp staticRoot, (err)->
            logger.error err
            throw err

    describe "# Basic test", ->
        jcs = JcsConstructor
           staticRoot: staticRoot
           jadeSrc: path.join sourceRoot, 'views'
           jadeDst: path.join staticRoot, 'html'


