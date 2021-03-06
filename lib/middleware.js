/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

/* ########################################
 * Imports
 * ########################################
 */
var logger      = require('./logger').logger
  , glob        = require('glob')
  , async       = require('async')
  , fs          = require('fs')
  , url         = require('url')
  , path        = require('path')
  , Compiler    = require('./compiler')
  ;

/* ########################################
 * Variables
 * ########################################
 */
var TYPE_DEF_KEYS = {
    'stylus': {
        kSrcRoot:  'stylusSrc',
        kDstRoot:  'stylusDst',
        dstSuffix: '.css',
        srcSuffix: '.styl'
    },
    'less': {
        kSrcRoot:  'lessSrc',
        kDstRoot:  'lessDst',
        dstSuffix: '.css',
        srcSuffix: '.less'
    },
    'coffee': {
        kSrcRoot:  'coffeeSrc',
        kDstRoot:  'coffeeDst',
        dstSuffix: '.js',
        srcSuffix: '.coffee'
    },
    'jade': {
        kSrcRoot:  'jadeSrc',
        kDstRoot:  'jadeDst',
        dstSuffix: '.html',
        srcSuffix: '.jade'
    },
    'ejs': {
        kSrcRoot: 'ejsSrc',
        kDstRoot: 'ejsDst',
        dstSuffix: '.html',
        srcSuffix: '.ejs'
    }
};

/* ########################################
 * Helper class to abstract "types"
 * ########################################
 */
function TypeDef(which, opt){
    function calcPrefix(dst){
        return opt.urlBase + dst.substring(opt.staticRoot.length).replace(/^\\/, '/');
    }

    function replaceSuffix(str, from, to){
        return str.substring(0, str.length - from.length) + to;
    }

    var keys = TYPE_DEF_KEYS[which];
    if (!keys){
        throw new Error("Unknow type: " + which);
    }

    this.srcRoot = opt[keys.kSrcRoot];
    this.dstRoot = (opt[keys.kDstRoot] || this.srcRoot).replace(/[\/\\]$/, '');
    this.dstSuffix = keys.dstSuffix;
    this.srcSuffix = keys.srcSuffix;
    this.prefix = calcPrefix(this.dstRoot);

    ////////////////////////////////////////
    // NOTE: dynamically requires language middleware module.
    this.middleware = require('./types/' + which + '-middleware')(opt);

    this.matchPath = function (p){
        return p.indexOf(this.prefix) === 0
            && p.lastIndexOf(this.dstSuffix) == (p.length - this.dstSuffix.length);
    }

    this.calcSrc = function (p){
        p = p.substring(this.prefix.length);
        return path.join(this.srcRoot, replaceSuffix(p, this.dstSuffix, this.srcSuffix));
    }

    this.calcDst = function (p){
        p = p.substring(this.prefix.length);
        return path.join(this.dstRoot, p);
    }

    this.srcExists = function (p){
        src = this.calcSrc(p);
        try {
            return fs.statSync(src).isFile();
        } catch (e){
            return false;
        }
    }

    this.src2Dst = function (src) {
        src = src.substring(this.srcRoot.length);
        return path.join(this.dstRoot, replaceSuffix(src, this.srcSuffix, this.dstSuffix));
    }
}

/* ########################################
 * Return Express middleware with the given 'opt'.
 * ########################################
 */
function jcs(opt){
    opt = opt || {};

    // Set default opt.
    opt.bare    = opt.bare  || false;
    opt.force   = opt.force || false;
    opt.urlBase = (opt.urlBase || '').replace(/\/$/, '').replace(/^([^\/])/, '/$1');
    opt.encodeSrc = opt.encodeSrc === undefined ? false : opt.encodeSrc;

    var typeMap = [];
    for(var which in TYPE_DEF_KEYS){
        var keys = TYPE_DEF_KEYS[which];
        if(opt[keys.kSrcRoot]){
            typeMap.push(new TypeDef(which, opt));
        }
    }


    ////////////////////////////////////////
    // MIddleware
    this.middleware = function(req, res, next){

        // If not 'GET' nor 'HEAD', pass to next.
        var reqMethod = req.method.toUpperCase();
        if ('GET' != reqMethod && 'HEAD' != reqMethod){
            logger.debug("Skip '" + reqMethod + "' request method.");
            return next();
        }

        // e.g.
        // pathname: /<coffeeRoot>/path/to/script.js
        var pathname = url.parse(req.url).pathname;

        // See if the request matches one of the middlewares.
        logger.info('[lookup] pathname=' + pathname);
        for(var i = 0; i < typeMap.length; i++){
            var typeDef = typeMap[i];
            if(!typeDef.matchPath(pathname)){
                continue;
            }

            var srcPath = typeDef.calcSrc(pathname);
            var dstPath = typeDef.calcDst(pathname);
            if(!typeDef.srcExists(pathname)){
                continue;
            }

            logger.info('[lookup] typeDef.name ' +  typeDef.middleware.name);
            var compiler = new Compiler(srcPath, dstPath, typeDef.middleware, next);

            // If option 'force' provided, force compile
            if (opt.force)
                compiler.compile();
            else
                compiler.process();
            return
        }

        // Type not found, forward to next handler
        logger.debug("No typedef found for pathname: " + pathname);
        return next();
    };

    ////////////////////////////////////////
    // Prepare all the static resources.
    this.prepare = function(next){
        var files = [];
        for(var i = 0; i < typeMap.length; i++){
            var t = typeMap[i];
            var list = glob.sync(t.srcRoot + '/**/*' + t.srcSuffix);
            for(var j = 0; j < list.length; j++){
                files.push({t: t, f: list[j]});
            }
        }

        async.each(files, function(i, cb){
            var src = path.normalize(i.f)
            var dst = i.t.src2Dst(src);
            var compiler = new Compiler(src, dst, i.t.middleware, cb);
            compiler.compile();
        }, function(err){
            if (err){
                logger.error(err);
            } else {
                console.log("DONE!");
            }
            if (next){
                next(err);
            }
        });
    };
}

/* ########################################
 * Export middleware
 * ########################################
 */
module.exports = function(opt){
    return new jcs(opt);
};

