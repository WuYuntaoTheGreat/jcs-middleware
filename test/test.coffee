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
    # level: 'trace'
    level: 'info'
    format:
        dateTime: "HH:mm:ss.SSS"
        message: "%d [%t] - %m"

JcsConstructor = (opt) ->
    require("../index")(opt).middleware

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


describe "THE TEST FOR JCS MIDDLEWARE", ->
    beforeEach (done)->
        #logger.info "deleting public folder..."
        rmdir STATICROOT, (err)->
            if err
                logger.error err
                #The folder may not exist.
                # throw err
                #
            #logger.info "creating public folder..."
            mkdirp STATICROOT, (err)->
                if err
                    logger.error err
                    throw err
                else
                    done()

    describe "Test stylus middleware", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           stylusSrc: path.join SOURCEROOT, 'stylus'
           stylusDst: path.join STATICROOT, 'css'

        srcPath = path.join SOURCEROOT, 'stylus', 'a.styl'
        outPath = path.join STATICROOT, 'css', 'a.css'
        outUrl = EXAMPLESITE + '/css/a.css'


        it "#1 'a.styl' should be compiled to 'a.css'", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                done()

        it "#2 do twice without touch source, should not compile", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                outTime = fs.statSync(outPath).mtime
                jcs mockReq(outUrl), null, (err) ->
                    if err
                        logger.error err
                        logger.error err.stack
                    assert.ok !err
                    assert.ok fs.existsSync outPath
                    assert.notStrictEqual fs.statSync(outPath).mtime, outTime
                    done()


        it "#4 do twice with touch source, should compile", (done) ->
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

        it "#5 touch included file, should compile", (done) ->
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

    describe "Test coffee middleware", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           coffeeSrc: path.join SOURCEROOT, 'coffee'
           coffeeDst: path.join STATICROOT, 'js'

        srcPath = path.join SOURCEROOT, 'coffee', 'a.coffee'
        outPath = path.join STATICROOT, 'js', 'a.js'
        outUrl = EXAMPLESITE + '/js/a.js'



        it "#1 'a.coffee' should be compiled to 'a.js'", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                done()

        it "#2 do twice without touch source, should not compile", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                outTime = fs.statSync(outPath).mtime
                jcs mockReq(outUrl), null, (err) ->
                    if err
                        logger.error err
                        logger.error err.stack
                    assert.ok !err
                    assert.ok fs.existsSync outPath
                    assert.notStrictEqual fs.statSync(outPath).mtime, outTime
                    done()

        it "#3 do twice with touch source, should compile", (done) ->
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

    describe "Test jade middleware", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           jadeSrc: path.join SOURCEROOT, 'jade'
           jadeDst: path.join STATICROOT, 'html'

        srcPath = path.join SOURCEROOT, 'jade', 'a.jade'
        outPath = path.join STATICROOT, 'html', 'a.html'
        outUrl = EXAMPLESITE + '/html/a.html'


        it "#1 'a.jade' should be compiled to 'a.html'", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                done()

        it "#2 do twice without touch source, should not compile", (done) ->
            jcs mockReq(outUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outPath
                outTime = fs.statSync(outPath).mtime
                jcs mockReq(outUrl), null, (err) ->
                    if err
                        logger.error err
                        logger.error err.stack
                    assert.ok !err
                    assert.ok fs.existsSync outPath
                    assert.notStrictEqual fs.statSync(outPath).mtime, outTime
                    done()

        it "#3 do twice with touch source, should compile", (done) ->
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

        outPathB = path.join STATICROOT, 'html', 'b.html'
        outUrlB = EXAMPLESITE + '/html/b.html'

        it "#4 touch included file, should compile", (done) ->
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

    describe "Test All middlewares, together", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           urlBase:   'prefix'
           stylusSrc: path.join SOURCEROOT, 'stylus'
           stylusDst: path.join STATICROOT, 'css'
           coffeeSrc: path.join SOURCEROOT, 'coffee'
           coffeeDst: path.join STATICROOT, 'js'
           jadeSrc: path.join SOURCEROOT, 'jade'
           jadeDst: path.join STATICROOT, 'html'

        examplesite = EXAMPLESITE + "/prefix"
        outCssUrl   = examplesite + "/css/a.css"
        outJsUrl    = examplesite + "/js/a.js"
        outHtmlUrl  = examplesite + "/html/a.html"
        outCssPath  = path.join STATICROOT, 'css', 'a.css'
        outJsPath   = path.join STATICROOT, 'js', 'a.js'
        outHtmlPath = path.join STATICROOT, 'html', 'a.html'

        it "#1 'POST' method should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/css/notexist.css', 'POST'), null, (err) ->
                assert.ok !err
                done()

        it "#2 Non exist stylus should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/css/notexist.css'), null, (err) ->
                assert.ok !err
                done()

        it "#3 Non exist coffee should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/js/notexist.js'), null, (err) ->
                assert.ok !err
                done()

        it "#4 Non exist jade should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/html/notexist.html'), null, (err) ->
                assert.ok !err
                done()

        it "#5 'a.styl' should be compiled to 'a.css', with prefix", (done) ->
            jcs mockReq(outCssUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outCssPath
                done()

        it "#6 'a.coffee' should be compiled to 'a.js', with prefix", (done) ->
            jcs mockReq(outJsUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outJsPath
                done()

        it "#7 'a.jade' should be compiled to 'a.html', with prefix", (done) ->
            jcs mockReq(outHtmlUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outHtmlPath
                done()

        it "#8 do twice without touch source, but with force, should compile", (done) ->
            this.timeout 3000
            jcs = JcsConstructor
               staticRoot: STATICROOT
               force: true
               urlBase:   'prefix'
               stylusSrc: path.join SOURCEROOT, 'stylus'
               stylusDst: path.join STATICROOT, 'css'
            jcs mockReq(outCssUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outCssPath
                outTime = fs.statSync(outCssPath).mtime

                setTimeout ()->
                    jcs mockReq(outCssUrl), null, (err) ->
                        if err
                            logger.error err
                            logger.error err.stack
                        assert.ok !err
                        assert.ok fs.existsSync outCssPath
                        assert.ok fs.statSync(outCssPath).mtime > outTime
                        done()
                , 1158

        it "#9 test compress", (done) ->
            jcs = JcsConstructor
               staticRoot: STATICROOT
               force: true
               compress: true
               urlBase:   'prefix'
               jadeSrc: path.join SOURCEROOT, 'jade'
               jadeDst: path.join STATICROOT, 'html'

            jcs mockReq(outHtmlUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outHtmlPath
                size1 = fs.statSync(outHtmlPath).size

                jcs = JcsConstructor
                   staticRoot: STATICROOT
                   force: true
                   compress: false
                   urlBase:   'prefix'
                   jadeSrc: path.join SOURCEROOT, 'jade'
                   jadeDst: path.join STATICROOT, 'html'

                jcs mockReq(outHtmlUrl), null, (err) ->
                    assert.ok !err
                    assert.ok fs.existsSync outHtmlPath
                    size2 = fs.statSync(outHtmlPath).size
                    assert.ok size2 > size1
                    done()

    describe "Test All middlewares, without prefix", ->
        jcs = JcsConstructor
           staticRoot: STATICROOT
           urlBase:   '/'
           stylusSrc: path.join SOURCEROOT, 'stylus'
           stylusDst: path.join STATICROOT, 'css'
           coffeeSrc: path.join SOURCEROOT, 'coffee'
           coffeeDst: path.join STATICROOT, 'js'
           jadeSrc: path.join SOURCEROOT, 'jade'
           jadeDst: path.join STATICROOT, 'html'

        examplesite = EXAMPLESITE
        outCssUrl   = examplesite + "/css/a.css"
        outJsUrl    = examplesite + "/js/a.js"
        outHtmlUrl  = examplesite + "/html/a.html"
        outCssPath  = path.join STATICROOT, 'css', 'a.css'
        outJsPath   = path.join STATICROOT, 'js', 'a.js'
        outHtmlPath = path.join STATICROOT, 'html', 'a.html'

        it "#1 'POST' method should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/css/notexist.css', 'POST'), null, (err) ->
                assert.ok !err
                done()

        it "#2 Non exist stylus should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/css/notexist.css'), null, (err) ->
                assert.ok !err
                done()

        it "#3 Non exist coffee should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/js/notexist.js'), null, (err) ->
                assert.ok !err
                done()

        it "#4 Non exist jade should return next directly, without error", (done) ->
            jcs mockReq(examplesite + '/html/notexist.html'), null, (err) ->
                assert.ok !err
                done()

        it "#5 'a.styl' should be compiled to 'a.css', with prefix", (done) ->
            jcs mockReq(outCssUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outCssPath
                done()

        it "#6 'a.coffee' should be compiled to 'a.js', with prefix", (done) ->
            jcs mockReq(outJsUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outJsPath
                done()

        it "#7 'a.jade' should be compiled to 'a.html', with prefix", (done) ->
            jcs mockReq(outHtmlUrl), null, (err) ->
                assert.ok !err
                assert.ok fs.existsSync outHtmlPath
                done()

