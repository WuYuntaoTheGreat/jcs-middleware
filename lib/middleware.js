/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

var logger          = require('nice-logger').logger
  , fs              = require('fs')
  , url             = require('url')
  , path            = require('path')
  , mkdirp          = require('mkdirp')
  , filecomp        = require('./filecomp')
  ;


///**
// * get the overlaping path from the end of path A, and the begining of path B.
// *
// * @param {String} pathA
// * @param {String} pathB
// * @return {String}
// * @api private
// */
//
//function compare(pathA, pathB) {
//    pathA = pathA.split(sep);
//    pathB = pathB.split(sep);
//    var overlap = [];
//    while (pathA[pathA.length - 1] == pathB[0]) {
//        overlap.push(pathA.pop());
//        pathB.shift();
//    }
//    return overlap.join(sep);
//}

/**
 * Return Express middleware with the given 'opt'.
 */
module.exports = function(opt){
    opt = opt || {};

    // Set default opt.
    opt.once    = opt.once  || false; 
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
        for(var i = 0; i < typeMap.length; i++){
            var t = typeMap[i];
            if(pathname.indexOf(t.prefix) === 0 && t.suffix.test(pathname)){
                typeDef = typeMap[i];
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


        // The real compile function.
        // This glues middleware compile functions and file system handling together.
        var compile = function(){
            logger.debug('reading', srcPath);
            fs.readFile(srcPath, 'utf8', function(err, str){
                // If no corresponding source file found, it's not a real error, just pass to 
                // next handler.
                if (err){
                    return next('ENOENT' == err.code ? null : err);
                }

                try {
                    typeDef.middleware.compile(str, srcPath, dstPath, function(result){
                        mkdirp(path.dirname(dstPath), function(err){
                            // mkdirp should not have any error.
                            if (err) return next(err);
                            // Here we call real 'next', instead of return the compiled content
                            // back to http response, because we don't know (care) other
                            // information of the response, e.g. mimetype, content-type, etc.
                            //
                            // The next handler should be responsible to handle 'static' files
                            // just generated.
                            fs.writeFile(dstPath, result, 'utf8', next);
                        });
                    });
                } catch (err){
                    logger.error("compile err: ", err);
                    logger.error(err.stack);
                    return next(err);
                }
            });
        };

        // Unconditional compile.
        if (opt.force) return compile();

        // Call file comp module to handle the file timestamp check, etc.
        filecomp( dstPath
                , srcPath
                , typeDef.middleware.dependencies(srcPath)
                , {
                    onError: next,
                    onIgnore: next,
                    onChanged: compile
                }
        );

    }
}

