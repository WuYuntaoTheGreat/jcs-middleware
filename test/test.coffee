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

STATICROOT = path.join __dirname, "public"
SOURCEROOT = path.join __dirname, "views"
EXAMPLESITE = "http://yourdomain.com"

# Change the file timestamp.
touch = (f, d) ->
    d = d || new Date
    fs.utimesSync f, d, d

mockReq = (url, method) ->
    method = method || 'GET'
    {
        url: url
        method: method
    }


describe "The test for jcs middleware", ->
    beforeEach (done)->
        rmdir STATICROOT, (err)->
            if err
                logger.error err
                throw err
            else
                mkdirp STATICROOT, (err)->
                    if err
                        logger.error err
                        throw err
                    else
                        done()

    describe "# Basic test", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           jadeSrc: path.join SOURCEROOT, 'jade'
           jadeDst: path.join STATICROOT, 'html'

        it "'POST' method should return next directly, without error", (done) ->
            jcs mockReq(EXAMPLESITE + '/notexist', 'POST'), null, (err) ->
                assert.strictEqual err, undefined
                done()

        it "Non exist jade should return next directly, without error", (done) ->
            jcs mockReq(EXAMPLESITE + '/html/notexist.html'), null, (err) ->
                assert.strictEqual err, undefined
                done()

        it "'a.jade' should be compiled to 'a.html'", (done) ->
            jcs mockReq(EXAMPLESITE + '/html/a.html'), null, (err) ->
                assert.strictEqual err, undefined
                assert.ok fs.existsSync path.join STATICROOT, 'html', 'a.html'
                done()
