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

#require('nice-logger').init
#    # level: 'trace'
#    level: 'info'
#    format:
#        dateTime: "HH:mm:ss.SSS"
#        message: "%d [%t] - %m"

STATICROOT  = path.join __dirname, "public"
SOURCEROOT  = path.join __dirname, "views"
EXAMPLESITE = "http://yourdomain.com"
PREFIX      = "prefix"


# All the test data
#
# a - testcase 'A'
# b - testcase 'B'
# x - testcase NOT EXIST
#
#   .src  - source file path
#   .dst  - destination file path
#   .url  - plain url
#   .urlP - url with prefix
#
R =
    stylus:
        _dst: 'css'
        _srcSuffix: 'styl'
        a: {}
        b: {}
        x: {}
    coffee:
        _dst: 'js'
        a: {}
        x: {}
    jade:
        _dst: 'html'
        a: {}
        b: {}
        x: {}
    ejs:
        _dst: 'html'
        a: {}
        b: {}
        x: {}
    less:
        _dst: 'css'
        a: {}
        x: {}

for i, cjh of R
    for k of cjh when k[0] != '_'
        cjh[k] =
            src : path.join SOURCEROOT, i, "#{k}.#{cjh._srcSuffix || i}"
            dst : path.join STATICROOT, cjh._dst, "#{k}.#{cjh._dst}"
            url : "#{EXAMPLESITE}/#{cjh._dst}/#{k}.#{cjh._dst}"
            urlP: "#{EXAMPLESITE}/#{PREFIX}/#{cjh._dst}/#{k}.#{cjh._dst}"

logger.info R

# Shorthand function to create jcs instance.
createJcsObj = (which, extra) ->
    opt = extra || {}
    opt.staticRoot = STATICROOT
    which.split(/[\s\|,;]+/).forEach (w) ->
        if /^[sS]/.test w
           opt.stylusSrc= path.join SOURCEROOT, 'stylus'
           opt.stylusDst= path.join STATICROOT, 'css'
        if /^[lL]/.test w
            opt.lessSrc = path.join SOURCEROOT, 'less'
            opt.lessDst = path.join STATICROOT, 'css'
        if /^[jJ]/.test w
           opt.jadeSrc  = path.join SOURCEROOT, 'jade'
           opt.jadeDst  = path.join STATICROOT, 'html'
        if /^[eE]/.test w
            opt.ejsSrc  = path.join SOURCEROOT, 'ejs'
            opt.ejsDst  = path.join STATICROOT, 'html'
        if /^[cC]/.test w
           opt.coffeeSrc= path.join SOURCEROOT, 'coffee'
           opt.coffeeDst= path.join STATICROOT, 'js'

    require("../index")(opt)

createJcs = (which, extra) ->
    createJcsObj(which, extra).middleware


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

describe "ALL", ->
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
                jcs mockReq(R.stylus.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.a.dst
                    done()

            it "#2 do twice without touch source, should not compile", (done) ->
                jcs mockReq(R.stylus.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.a.dst
                    outTime = fs.statSync(R.stylus.a.dst).mtime
                    jcs mockReq(R.stylus.a.url), null, (err) ->
                        if err
                            logger.error err
                            logger.error err.stack
                        assert.ok !err
                        assert.ok fs.existsSync R.stylus.a.dst
                        assert.notStrictEqual fs.statSync(R.stylus.a.dst).mtime, outTime
                        done()


            it "#4 do twice with touch source, should compile", (done) ->
                this.timeout 3000
                jcs mockReq(R.stylus.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.a.dst
                    outTime = fs.statSync(R.stylus.a.dst).mtime

                    setTimeout ()->
                        touch R.stylus.a.src

                        jcs mockReq(R.stylus.a.url), null, (err) ->
                            assert.ok !err
                            assert.ok fs.existsSync R.stylus.a.dst
                            outTime2 = fs.statSync(R.stylus.a.dst).mtime
                            logger.debug "t1=%s", outTime
                            logger.debug "t2=%s", outTime2
                            assert.ok outTime2 > outTime
                            done()
                    , 1234


            it "#5 touch included file, should compile", (done) ->
                this.timeout 3000

                jcs mockReq(R.stylus.b.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.b.dst
                    outTime = fs.statSync(R.stylus.b.dst).mtime

                    setTimeout ()->
                        touch R.stylus.a.src

                        jcs mockReq(R.stylus.b.url), null, (err) ->
                            assert.ok !err
                            assert.ok fs.existsSync R.stylus.b.dst
                            outTime2 = fs.statSync(R.stylus.b.dst).mtime
                            logger.debug "t1=%s", outTime
                            logger.debug "t2=%s", outTime2
                            assert.ok outTime2 > outTime
                            done()
                    , 1234

        ############################################################
        # Test less middleware
        describe.only "Test less middleware", ->
            jcs = createJcs 'l'

            it "#1 'a.less' should be compiled to 'a.css'", (done) ->
                jcs mockReq(R.less.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.less.a.dst
                    done()

        ############################################################
        # Test coffee middleware
        describe "Test coffee middleware", ->
            jcs = createJcs 'c'

            it "#1 'a.coffee' should be compiled to 'a.js'", (done) ->
                jcs mockReq(R.coffee.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.coffee.a.dst
                    done()

            it "#2 do twice without touch source, should not compile", (done) ->
                jcs mockReq(R.coffee.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.coffee.a.dst
                    outTime = fs.statSync(R.coffee.a.dst).mtime
                    jcs mockReq(R.coffee.a.url), null, (err) ->
                        if err
                            logger.error err
                            logger.error err.stack
                        assert.ok !err
                        assert.ok fs.existsSync R.coffee.a.dst
                        assert.notStrictEqual fs.statSync(R.coffee.a.dst).mtime, outTime
                        done()

            it "#3 do twice with touch source, should compile", (done) ->
                this.timeout 3000
                jcs mockReq(R.coffee.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.coffee.a.dst
                    outTime = fs.statSync(R.coffee.a.dst).mtime

                    setTimeout ()->
                        touch R.coffee.a.src

                        jcs mockReq(R.coffee.a.url), null, (err) ->
                            assert.ok !err
                            assert.ok fs.existsSync R.coffee.a.dst
                            outTime2 = fs.statSync(R.coffee.a.dst).mtime
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
                jcs mockReq(R.jade.b.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.b.dst
                    done()

            it "#2 do twice without touch source, should not compile", (done) ->
                jcs mockReq(R.jade.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.a.dst
                    outTime = fs.statSync(R.jade.a.dst).mtime
                    jcs mockReq(R.jade.a.url), null, (err) ->
                        if err
                            logger.error err
                            logger.error err.stack
                        assert.ok !err
                        assert.ok fs.existsSync R.jade.a.dst
                        assert.notStrictEqual fs.statSync(R.jade.a.dst).mtime, outTime
                        done()

            it "#3 do twice with touch source, should compile", (done) ->
                this.timeout 3000
                jcs mockReq(R.jade.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.a.dst
                    outTime = fs.statSync(R.jade.a.dst).mtime

                    setTimeout ()->
                        touch R.jade.a.src

                        jcs mockReq(R.jade.a.url), null, (err) ->
                            assert.ok !err
                            assert.ok fs.existsSync R.jade.a.dst
                            outTime2 = fs.statSync(R.jade.a.dst).mtime
                            logger.debug "t1=%s", outTime
                            logger.debug "t2=%s", outTime2
                            assert.ok outTime2 > outTime
                            done()
                    , 1234

            it "#4 touch included file, should compile", (done) ->
                this.timeout 3000

                jcs mockReq(R.jade.b.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.b.dst
                    outTime = fs.statSync(R.jade.b.dst).mtime

                    setTimeout ()->
                        # Touch 'a', which is included by 'b'
                        touch R.jade.a.src

                        jcs mockReq(R.jade.b.url), null, (err) ->
                            assert.ok !err
                            assert.ok fs.existsSync R.jade.b.dst
                            outTime2 = fs.statSync(R.jade.b.dst).mtime
                            logger.debug "t1=%s", outTime
                            logger.debug "t2=%s", outTime2
                            assert.ok outTime2 > outTime
                            done()
                    , 1234

        ############################################################
        # Test ejs
        describe "Test ejs middleware", ->
            jcs = createJcs 'e'

            it "#1 'b.ejs' should be compiled to 'b.html'", (done) ->
                jcs mockReq(R.ejs.b.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.ejs.b.dst
                    assert.ok fs.statSync(R.ejs.b.dst).size == 0
                    done()

            it "#2 do twice without touch source, should not compile", (done) ->
                jcs mockReq(R.ejs.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.ejs.a.dst
                    outTime = fs.statSync(R.ejs.a.dst).mtime
                    jcs mockReq(R.ejs.a.url), null, (err) ->
                        if err
                            logger.error err
                            logger.error err.stack
                        assert.ok !err
                        assert.ok fs.existsSync R.ejs.a.dst
                        assert.notStrictEqual fs.statSync(R.ejs.a.dst).mtime, outTime
                        done()

            it "#3 do twice with touch source, should compile", (done) ->
                this.timeout 3000
                jcs mockReq(R.ejs.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.ejs.a.dst
                    outTime = fs.statSync(R.ejs.a.dst).mtime

                    setTimeout ()->
                        touch R.ejs.a.src

                        jcs mockReq(R.ejs.a.url), null, (err) ->
                            assert.ok !err
                            assert.ok fs.existsSync R.ejs.a.dst
                            outTime2 = fs.statSync(R.ejs.a.dst).mtime
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
                jcs mockReq(R.stylus.x.urlP, 'POST'), null, (err) ->
                    assert.ok !err
                    done()

            it "#2 Non exist stylus should return next directly, without error", (done) ->
                jcs mockReq(R.stylus.x.urlP), null, (err) ->
                    assert.ok !err
                    done()

            it "#3 Non exist coffee should return next directly, without error", (done) ->
                jcs mockReq(R.coffee.x.urlP), null, (err) ->
                    assert.ok !err
                    done()

            it "#4 Non exist jade should return next directly, without error", (done) ->
                jcs mockReq(R.jade.x.urlP), null, (err) ->
                    assert.ok !err
                    done()

            it "#5 Non exist ejs should return next directly, without error", (done) ->
                jcs mockReq(R.ejs.x.urlP), null, (err) ->
                    assert.ok !err
                    done()

            it "#6 'a.styl' should be compiled to 'a.css', with prefix", (done) ->
                jcs mockReq(R.stylus.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.a.dst
                    done()

            it "#7 'a.coffee' should be compiled to 'a.js', with prefix", (done) ->
                jcs mockReq(R.coffee.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.coffee.a.dst
                    done()

            it "#8 'a.jade' should be compiled to 'a.html', with prefix", (done) ->
                jcs mockReq(R.jade.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.a.dst
                    done()

            it "#9 'a.ejs' should be compiled to 'a.html', with prefix", (done) ->
                jcs mockReq(R.ejs.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.ejs.a.dst
                    done()


            it "#10 do twice without touch source, but with force, should compile", (done) ->
                this.timeout 3000
                jcs = createJcs 's',
                   force: true
                   urlBase: 'prefix'

                jcs mockReq(R.stylus.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.a.dst
                    outTime = fs.statSync(R.stylus.a.dst).mtime

                    setTimeout ()->
                        jcs mockReq(R.stylus.a.urlP), null, (err) ->
                            if err
                                logger.error err
                                logger.error err.stack
                            assert.ok !err
                            assert.ok fs.existsSync R.stylus.a.dst
                            assert.ok fs.statSync(R.stylus.a.dst).mtime > outTime
                            done()
                    , 1158

            it "#11 test compress", (done) ->
                jcs = createJcs 'j',
                   force: true
                   compress: true
                   urlBase:   'prefix'

                jcs mockReq(R.jade.a.urlP), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.a.dst
                    size1 = fs.statSync(R.jade.a.dst).size

                    jcs = createJcs 'j',
                       force: true
                       compress: false
                       urlBase:   'prefix'

                    jcs mockReq(R.jade.a.urlP), null, (err) ->
                        assert.ok !err
                        assert.ok fs.existsSync R.jade.a.dst
                        size2 = fs.statSync(R.jade.a.dst).size
                        assert.ok size2 > size1
                        done()

        ############################################################
        # Test All middlewares, without prefix
        describe "Test All middlewares, without prefix", ->
            jcs = createJcs 's|c|j',
               urlBase:   '/'

            examplesite = EXAMPLESITE

            it "#1 Non exist stylus should return next directly, without error", (done) ->
                jcs mockReq(R.stylus.x.url), null, (err) ->
                    assert.ok !err
                    done()

            it "#2 Non exist coffee should return next directly, without error", (done) ->
                jcs mockReq(R.coffee.x.url), null, (err) ->
                    assert.ok !err
                    done()

            it "#3 Non exist jade should return next directly, without error", (done) ->
                jcs mockReq(R.jade.x.url), null, (err) ->
                    assert.ok !err
                    done()

            it "#4 'a.styl' should be compiled to 'a.css', with prefix", (done) ->
                jcs mockReq(R.stylus.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.stylus.a.dst
                    done()

            it "#5 'a.coffee' should be compiled to 'a.js', with prefix", (done) ->
                jcs mockReq(R.coffee.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.coffee.a.dst
                    done()

            it "#6 'a.jade' should be compiled to 'a.html', with prefix", (done) ->
                jcs mockReq(R.jade.a.url), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync R.jade.a.dst
                    done()

        ############################################################
        # Test parallel...
        describe "Test parallel...", ->
            jcs = createJcs 's|c|j'

            it "#1 'parallel'", (done) ->
                this.timeout 2000
                async.detect [
                    R.stylus.a
                    R.stylus.b
                    R.coffee.a
                    R.jade.a
                    R.jade.b
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



        ############################################################
        # Test prepare static resources.
        describe "Test prepare static resources.", ->
            it "#1 'prepare'", (done) ->
                createJcsObj('s|c|j').prepare (err)->
                    assert.ok !err
                    async.detect [
                        R.stylus.a
                        R.stylus.b
                        R.coffee.a
                        R.jade.a
                        R.jade.b
                    ], (item, cb) ->
                        if !fs.existsSync item.dst
                            logger.error "'#{item.dst}' does not generated!"
                            cb true
                        else
                            cb false
                    , (result) ->
                        assert.ok !result
                        done()


        ############################################################
        # Test both ejs & jade
        describe "Test ejs overriding jade", ->
            jcs = createJcs 'e|j'
            it "#1 do both ejs & jade, should compile jade", (done) ->
                jcs mockReq(R.ejs.b.url), null, (err)->
                    assert.ok !err
                    assert.ok fs.existsSync R.ejs.b.dst
                    assert.ok fs.statSync(R.ejs.b.dst).size > 0
                    done()
