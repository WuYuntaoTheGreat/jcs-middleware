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

require('nice-logger').init
    level: 'trace'
    format:
        dateTime: "HH:mm:ss.SSS"
        message: "%d [%t] - %m"

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
        logger.info "deleting public folder..."
        rmdir STATICROOT, (err)->
            if err
                logger.error err
                #The folder may not exist.
                # throw err
                #
            logger.info "creating public folder..."
            mkdirp STATICROOT, (err)->
                if err
                    logger.error err
                    throw err
                else
                    done()

    describe "Basic test", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           stylusSrc: path.join SOURCEROOT, 'stylus'
           stylusDst: path.join STATICROOT, 'css'

        srcPath = path.join SOURCEROOT, 'stylus', 'a.styl'
        outPath = path.join STATICROOT, 'css', 'a.css'
        outUrl = EXAMPLESITE + '/css/a.css'

        it "#1 'POST' method should return next directly, without error", (done) ->
            jcs mockReq(EXAMPLESITE + '/notexist', 'POST'), null, (err) ->
                assert.ok !err
                done()

        it "#2 Non exist jade should return next directly, without error", (done) ->
            jcs mockReq(EXAMPLESITE + '/css/notexist.css'), null, (err) ->
                assert.ok !err
                done()

        it "#3 'a.styl' should be compiled to 'a.css'", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                done()

        it "#4 do twice without touch source, should not compile", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                outTime = fs.statSync(outPath).mtime
                jcs mockReq(outUrl), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync outPath
                    assert.notStrictEqual fs.statSync(outPath).mtime, outTime
                    done()

        it "#5 do twice with touch source, should compile", (done) ->
            this.timeout 3000
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                outTime = fs.statSync(outPath).mtime

                setTimeout ()->
                    logger.debug "src time before=", fs.statSync(srcPath).mtime
                    touch srcPath
                    logger.debug "src time  after=", fs.statSync(srcPath).mtime

                    jcs mockReq(outUrl), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync outPath
                        outTime2 = fs.statSync(outPath).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234


        outPathB = path.join STATICROOT, 'css', 'b.css'
        outUrlB = EXAMPLESITE + '/css/b.css'

        it "#6 touch included file, should compile", (done) ->
            this.timeout 3000

            jcs mockReq(outUrlB), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPathB
                outTime = fs.statSync(outPathB).mtime

                setTimeout ()->
                    logger.debug "src time before=", fs.statSync(srcPath).mtime
                    touch srcPath
                    logger.debug "src time  after=", fs.statSync(srcPath).mtime

                    jcs mockReq(outUrlB), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync outPathB
                        outTime2 = fs.statSync(outPathB).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234

