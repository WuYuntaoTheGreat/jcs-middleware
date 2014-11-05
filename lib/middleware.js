/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

var logger          = require('nice-logger').logger
  , url             = require('url')
  , path            = require('path')
  , Compiler        = require('./compiler')
  ;


/**
 * Return Express middleware with the given 'opt'.
 */
module.exports = function(opt){
    opt = opt || {};

    // Set default opt.
    opt.bare    = opt.bare  || false; 
    opt.force   = opt.force || false;
    opt.urlBase = (opt.urlBase || '').replace(/\/$/, '').replace(/^([^\/])/, '/$1');
    opt.encodeSrc = opt.encodeSrc === undefined ? false : opt.encodeSrc;

    // If *Src not defined, use empty string.
    opt.coffeeSrc = opt.coffeeSrc || '';
    opt.stylusSrc = opt.stylusSrc || '';
    opt.jadeSrc   = opt.jadeSrc   || '';

    // If *Dst opt are ommit, use *Src
    opt.coffeeDst = (opt.coffeeDst || opt.coffeeSrc).replace(/[\/\\]$/, '');
    opt.stylusDst = (opt.stylusDst || opt.stylusSrc).replace(/[\/\\]$/, '');
    opt.jadeDst   = (opt.jadeDst   || opt.jadeSrc  ).replace(/[\/\\]$/, '');

    function calcPrefix(dst){
        return opt.urlBase + dst.substring(opt.staticRoot.length).replace(/^\\/, '/');
    }

    var typeMap = [];
    if (opt.stylusSrc){
        typeMap.push({
            suffix: /\.css$/,
            srcSuffix: '.styl',
            srcRoot: opt.stylusSrc,
            dstRoot: opt.stylusDst,
            prefix : calcPrefix(opt.stylusDst),
            middleware: require('./stylus-middleware')(opt)
        });
    }
    if (opt.coffeeSrc){
        typeMap.push({
            suffix: /\.js$/,
            srcSuffix: '.coffee',
            srcRoot: opt.coffeeSrc,
            dstRoot: opt.coffeeDst,
            prefix : calcPrefix(opt.coffeeDst),
            middleware: require('./coffee-middleware')(opt)
        });
    }
    if (opt.jadeSrc){
        typeMap.push({
            suffix: /\.html$/,
            srcSuffix: '.jade',
            srcRoot: opt.jadeSrc,
            dstRoot: opt.jadeDst,
            prefix : calcPrefix(opt.jadeDst),
            middleware: require('./jade-middleware')(opt)
        });
    }


    // MIddleware
    return function(req, res, next){

        // If not 'GET' nor 'HEAD', pass to next.
        var reqMethod = req.method.toUpperCase();
        if ('GET' != reqMethod && 'HEAD' != reqMethod){
            logger.debug("Skip '%s' request method.", reqMethod);
            return next();
        }

        // e.g.
        // pathname: /<coffeeRoot>/path/to/script.js
        var pathname = url.parse(req.url).pathname;

        // See if the request matches one of the middlewares.
        var typeDef = null;
        logger.trace("==========");
        logger.trace('[lookup] pathname="%s"', pathname);
        for(var i = 0; i < typeMap.length; i++){
            var t = typeMap[i];
            if(pathname.indexOf(t.prefix) === 0 && t.suffix.test(pathname)){
                typeDef = typeMap[i];
                logger.trace('[lookup] typeDef.name "%s"', typeDef.middleware.name);
                break;
            }
        }

        if(!typeDef){
            logger.debug("No typedef found for pathname: %s", pathname);
            return next();
        }

        pathname = pathname.substring(typeDef.prefix.length);
        srcPath = path.join(typeDef.srcRoot, pathname.replace(typeDef.suffix, typeDef.srcSuffix));
        dstPath = path.join(typeDef.dstRoot, pathname);

        logger.debug("  dstPath='%s'", dstPath);
        logger.debug("  srcPath='%s'", srcPath);

        logger.trace('[outer] srcPath "%s"', srcPath);
        logger.trace('[outer] typeDef.name "%s"', typeDef.middleware.name);

        var compiler = new Compiler(srcPath, dstPath, typeDef.middleware, next);

        if (opt.force) 
            compiler.compile();
        else
            compiler.process();
    }
}

