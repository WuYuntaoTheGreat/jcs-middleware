/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

var logger          = require('graceful-logger')
  , fs              = require('fs')
  , url             = require('url')
  , path            = require('path')
  , mkdirp          = require('mkdirp')
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
 * Return Express middleware with the given 'options'.
 */

module.exports = function(options){
    options = options || {};

    // Set default options.
    options.once  = options.once  || false; 
    options.bare  = options.bare  || false; 
    options.force = options.force || false;
    options.encodeSrc = options.encodeSrc === undefined ? false : options.encodeSrc;

    // Check mandatory options.
    if (!options.coffeeSrc || !options.stylusSrc) {
        throw new Error("'coffeeSrc', 'stylusSrc', 'jadeSrc' and 'staticRoot' directories are " 
                + "required by jcs middleware");
    }

    // If *Dst options are ommit, use *Src
    options.coffeeDst = options.coffeeDst || options.coffeeSrc;
    options.stylusDst = options.stylusDst || options.stylusSrc;
    options.jadeDst   = options.jadeDst   || options.jadeSrc;

    var typeMap = [
        {
            suffix: /\.css$/,
            srcSuffix: '.styl',
            srcRoot: options.stylusSrc,
            dstRoot: options.stylusDst,
            prefix : options.stylusDst.substring(options.staticRoot.length),
            middleware: require('./lib/stylus-middleware')(options)
        },
        {
            suffix: /\.js$/,
            srcSuffix: '.coffee',
            srcRoot: options.coffeeSrc,
            dstRoot: options.coffeeDst,
            prefix : options.coffeeDst.substring(options.staticRoot.length),
            middleware: require('./lib/coffee-middleware')(options)
        },
        {
            suffix: /\.html$/,
            srcSuffix: '.jade',
            srcRoot: options.jadeSrc,
            dstRoot: options.jadeDst,
            prefix : options.jadeDst.substring(options.staticRoot.length),
            middleware: require('./lib/jade-middleware')(options)
        },
    ];


    // MIddleware
    return function(req, res, next){

        // If not 'GET' nor 'HEAD', pass to next.
        var reqMethod = req.method.toUpperCase();
        if ('GET' != reqMethod && 'HEAD' != reqMethod){
            return next();
        }

        // e.g.
        // pathname: /<coffeeRoot>/path/to/script.js
        var pathname = url.parse(req.url).pathname;

        // See if the request matches one of the middlewares.
        var typeDef = null;
        for(var i = 0; i < typeMap.length; i++){
            if(pathname.substring(typeMap[i].suffix) === 0 && typeMap[i].suffix.text(pathname)){
                typeDef = typeMap(i);
                break;
            }
        }
        if(!typeDef){
            return next();
        }

        srcPath = path.join(typeDef.srcRoot, pathname.replace(typeDef.suffix, typeDef.srcSuffix);
        dstPath = path.join(typeDef.dstRoot, pathname);

        logger.info("encounter", dstPath);
        logger.info("  srcPath", srcPath);


        // The real compile function.
        // This glues middleware compile functions and file system handling together.
        var compile = function(){
            logger.info('reading', srcPath);
            fs.readFile(srcPath, 'utf8', function(err, str){
                // If no corresponding source file found, it's not a real error, just pass to 
                // next handler.
                if (err)
                    return next('ENOENT' == err.code ? null : err);

                try {
                    typeDef.compile(str, srcPath, dstPath, function(result){
                        mkdirp(path.dirname(dstPath), 0700, function(err){
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
                    logger.error("compile err: %s ", err.message);
                    return next(err);
                }
            });
        };

        // Unconditional compile.
        if (options.force) return compile();

        // Call file comp module to handle the file timestamp check, etc.
        require('./lib/filecomp')(dstPath, srcPath, typeDef.dependencies(srcPath), {
            onError: next,
            onIgnore: next,
            onChanged: compile
        });

    }
}
