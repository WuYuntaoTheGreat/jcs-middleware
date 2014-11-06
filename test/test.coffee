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
async   = require "async"

require('nice-logger').init
    # level: 'trace'
    level: 'info'
    format:
        dateTime: "HH:mm:ss.SSS"
        message: "%d [%t] - %m"

JcsConstructor = (opt) ->
    require("../index")(opt).middleware

STATICROOT  = path.join __dirname, "public"
SOURCEROOT  = path.join __dirname, "views"
EXAMPLESITE = "http://yourdomain.com"
PREFIX      = "prefix"

R =
    css:
        _src: 'stylus'
        _srcSuffix: 'styl'
        a: {}
        b: {}
        x: {}
    js:
        _src: 'coffee'
        a: {}
        x: {}
    html:
        _src: 'jade'
        a: {}
        b: {}
        x: {}

for i, cjh of R
    for k of cjh when k[0] != '_'
        cjh[k] =
            src : path.join SOURCEROOT, cjh._src, k + '.' + (cjh._srcSuffix || cjh._src)
            dst : path.join STATICROOT, i, k + '.' + i
            url : EXAMPLESITE + '/' + i + '/' + k + '.' + i
            urlP: EXAMPLESITE + '/' + PREFIX + '/' + i + '/' + k + '.' + i

logger.info R


# Change the file timestamp.
touch = (f, d) ->
    d = d || new Date
    fs.utimesSync f, d, d


# Create a mockup http request object.
mockReq = (url, method) ->
    {
        url: url
        method: method || 'GET'
    }

# Shorthand function to create jcs instance.
createJcs = (which, extra) ->
    opt = extra || {}
    opt.staticRoot = STATICROOT
    which.split(/[\s\|,;]+/).forEach (w) ->
        if /^[sS]/.test w
           opt.stylusSrc= path.join SOURCEROOT, 'stylus'
           opt.stylusDst= path.join STATICROOT, 'css'
        if /^[cC]/.test w
           opt.coffeeSrc= path.join SOURCEROOT, 'coffee'
           opt.coffeeDst= path.join STATICROOT, 'js'
        if /^[jJ]/.test w
           opt.jadeSrc  = path.join SOURCEROOT, 'jade'
           opt.jadeDst  = path.join STATICROOT, 'html'

    JcsConstructor opt



describe "THE TEST FOR JCS MIDDLEWARE", ->
    # Before each test case. we need to clear the output folder.
    # This is done by:
    # 1) Delete the whole directory, with its contents.
    # 2) And then create that directory again.
    #
    beforeEach (done)->
        rmdir STATICROOT, (err)->
            if err
                logger.error err
            mkdirp STATICROOT, (err)->
                if err
                    logger.error err
                    throw err
                else
                    done()

    ############################################################
    # Test stylus middleware
    describe "Test stylus middleware", ->
        jcs = createJcs 's'

        it "#1 'a.styl' should be compiled to 'a.css'", (done) ->
            jcs mockReq(R.css.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.a.dst
                done()

        it "#2 do twice without touch source, should not compile", (done) ->
            jcs mockReq(R.css.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.a.dst
                outTime = fs.statSync(R.css.a.dst).mtime
                jcs mockReq(R.css.a.url), null, (err) ->
                    if err
                        logger.error err
                        logger.error err.stack
                    assert.ok !err
                    assert.ok fs.existsSync R.css.a.dst
                    assert.notStrictEqual fs.statSync(R.css.a.dst).mtime, outTime
                    done()


        it "#4 do twice with touch source, should compile", (done) ->
            this.timeout 3000
            jcs mockReq(R.css.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.a.dst
                outTime = fs.statSync(R.css.a.dst).mtime

                setTimeout ()->
                    touch R.css.a.src

                    jcs mockReq(R.css.a.url), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync R.css.a.dst
                        outTime2 = fs.statSync(R.css.a.dst).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234


        it "#5 touch included file, should compile", (done) ->
            this.timeout 3000

            jcs mockReq(R.css.b.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.b.dst
                outTime = fs.statSync(R.css.b.dst).mtime

                setTimeout ()->
                    touch R.css.a.src

                    jcs mockReq(R.css.b.url), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync R.css.b.dst
                        outTime2 = fs.statSync(R.css.b.dst).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234

    ############################################################
    # Test coffee middleware
    describe "Test coffee middleware", ->
        jcs = createJcs 'c'

        it "#1 'a.coffee' should be compiled to 'a.js'", (done) ->
            jcs mockReq(R.js.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.js.a.dst
                done()

        it "#2 do twice without touch source, should not compile", (done) ->
            jcs mockReq(R.js.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.js.a.dst
                outTime = fs.statSync(R.js.a.dst).mtime
                jcs mockReq(R.js.a.url), null, (err) ->
                    if err
                        logger.error err
                        logger.error err.stack
                    assert.ok !err
                    assert.ok fs.existsSync R.js.a.dst
                    assert.notStrictEqual fs.statSync(R.js.a.dst).mtime, outTime
                    done()

        it "#3 do twice with touch source, should compile", (done) ->
            this.timeout 3000
            jcs mockReq(R.js.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.js.a.dst
                outTime = fs.statSync(R.js.a.dst).mtime

                setTimeout ()->
                    touch R.js.a.src

                    jcs mockReq(R.js.a.url), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync R.js.a.dst
                        outTime2 = fs.statSync(R.js.a.dst).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234

    ############################################################
    # Test jade middleware
    describe "Test jade middleware", ->
        jcs = createJcs 'j'

        it "#1 'a.jade' should be compiled to 'a.html'", (done) ->
            jcs mockReq(R.html.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.a.dst
                done()

        it "#2 do twice without touch source, should not compile", (done) ->
            jcs mockReq(R.html.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.a.dst
                outTime = fs.statSync(R.html.a.dst).mtime
                jcs mockReq(R.html.a.url), null, (err) ->
                    if err
                        logger.error err
                        logger.error err.stack
                    assert.ok !err
                    assert.ok fs.existsSync R.html.a.dst
                    assert.notStrictEqual fs.statSync(R.html.a.dst).mtime, outTime
                    done()

        it "#3 do twice with touch source, should compile", (done) ->
            this.timeout 3000
            jcs mockReq(R.html.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.a.dst
                outTime = fs.statSync(R.html.a.dst).mtime

                setTimeout ()->
                    touch R.html.a.src

                    jcs mockReq(R.html.a.url), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync R.html.a.dst
                        outTime2 = fs.statSync(R.html.a.dst).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234

        it "#4 touch included file, should compile", (done) ->
            this.timeout 3000

            jcs mockReq(R.html.b.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.b.dst
                outTime = fs.statSync(R.html.b.dst).mtime

                setTimeout ()->
                    # Touch 'a', which is included by 'b'
                    touch R.html.a.src

                    jcs mockReq(R.html.b.url), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync R.html.b.dst
                        outTime2 = fs.statSync(R.html.b.dst).mtime
                        logger.debug "t1=%s", outTime
                        logger.debug "t2=%s", outTime2
                        assert.ok outTime2 > outTime
                        done()
                , 1234

    ############################################################
    # Test All middlewares, together
    describe "Test All middlewares, together", ->
        jcs = createJcs 's|c|j',
           urlBase:  PREFIX

        it "#1 'POST' method should return next directly, without error", (done) ->
            jcs mockReq(R.css.x.urlP, 'POST'), null, (err) ->
                assert.ok !err
                done()

        it "#2 Non exist stylus should return next directly, without error", (done) ->
            jcs mockReq(R.css.x.urlP), null, (err) ->
                assert.ok !err
                done()

        it "#3 Non exist coffee should return next directly, without error", (done) ->
            jcs mockReq(R.js.x.urlP), null, (err) ->
                assert.ok !err
                done()

        it "#4 Non exist jade should return next directly, without error", (done) ->
            jcs mockReq(R.html.x.urlP), null, (err) ->
                assert.ok !err
                done()

        it "#5 'a.styl' should be compiled to 'a.css', with prefix", (done) ->
            jcs mockReq(R.css.a.urlP), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.a.dst
                done()

        it "#6 'a.coffee' should be compiled to 'a.js', with prefix", (done) ->
            jcs mockReq(R.js.a.urlP), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.js.a.dst
                done()

        it "#7 'a.jade' should be compiled to 'a.html', with prefix", (done) ->
            jcs mockReq(R.html.a.urlP), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.a.dst
                done()

        it "#8 do twice without touch source, but with force, should compile", (done) ->
            this.timeout 3000
            jcs = createJcs 's',
               force: true
               urlBase: 'prefix'

            jcs mockReq(R.css.a.urlP), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.a.dst
                outTime = fs.statSync(R.css.a.dst).mtime

                setTimeout ()->
                    jcs mockReq(R.css.a.urlP), null, (err) ->
                        if err
                            logger.error err
                            logger.error err.stack
                        assert.ok !err
                        assert.ok fs.existsSync R.css.a.dst
                        assert.ok fs.statSync(R.css.a.dst).mtime > outTime
                        done()
                , 1158

        it "#9 test compress", (done) ->
            jcs = createJcs 'j',
               force: true
               compress: true
               urlBase:   'prefix'

            jcs mockReq(R.html.a.urlP), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.a.dst
                size1 = fs.statSync(R.html.a.dst).size

                jcs = createJcs 'j',
                   force: true
                   compress: false
                   urlBase:   'prefix'

                jcs mockReq(R.html.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.html.a.dst
                    size2 = fs.statSync(R.html.a.dst).size
                    assert.ok size2 > size1
                    done()

    ############################################################
    # Test All middlewares, without prefix
    describe "Test All middlewares, without prefix", ->
        jcs = createJcs 's|c|j',
           urlBase:   '/'

        examplesite = EXAMPLESITE

        it "#1 Non exist stylus should return next directly, without error", (done) ->
            jcs mockReq(R.css.x.url), null, (err) ->
                assert.ok !err
                done()

        it "#2 Non exist coffee should return next directly, without error", (done) ->
            jcs mockReq(R.js.x.url), null, (err) ->
                assert.ok !err
                done()

        it "#3 Non exist jade should return next directly, without error", (done) ->
            jcs mockReq(R.html.x.url), null, (err) ->
                assert.ok !err
                done()

        it "#4 'a.styl' should be compiled to 'a.css', with prefix", (done) ->
            jcs mockReq(R.css.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.css.a.dst
                done()

        it "#5 'a.coffee' should be compiled to 'a.js', with prefix", (done) ->
            jcs mockReq(R.js.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.js.a.dst
                done()

        it "#6 'a.jade' should be compiled to 'a.html', with prefix", (done) ->
            jcs mockReq(R.html.a.url), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync R.html.a.dst
                done()

    ############################################################
    # Test parallel...
    describe "Test parallel...", ->
        jcs = createJcs 's|c|j'

        it "#1 dito", (done) ->
            this.timeout 2000
            async.detect [
                R.css.a
                R.css.b
                R.js.a
                R.html.a
                R.html.b
            ], (item, cb) ->
                jcs mockReq(item.url), null, (err) ->
                    if err
                        logger.error err
                        cb true
                    else if !fs.existsSync item.dst
                        logger.error "Error: #{item.dst} not generated!"
                        cb true
                    else
                        cb false
            , (result) ->
                assert.ok !result
                done()


