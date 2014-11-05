/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

var logger          = require('nice-logger').logger
  , fs              = require('fs')
  , path            = require('path')
  , mkdirp          = require('mkdirp')
  , async           = require('async')
  ;

module.exports = Compiler = function(src, dst, middleware, next){
    this.src = src;
    this.dst = dst;
    this.middleware = middleware;
    this.next = next;

    this.compile = function() {
        logger.trace('[Compiler] srcPath "%s"', this.src);
        logger.trace('[Compiler] middleware.name "%s"', middleware.name);

        (function(that){
        fs.readFile(that.src, 'utf8', function(err, str){
            // If no corresponding source file found, it's not a real error, just pass to 
            // next handler.
            if (err){
                return that.next('ENOENT' == err.code ? null : err);
            }

            try {
                that.middleware.compile(str, that.src, that.dst, function(result){
                    mkdirp(path.dirname(that.dst), function(err){
                        // mkdirp should not have any error.
                        if (err) return that.next(err);
                        // Here we call real 'next', instead of return the compiled content
                        // back to http response, because we don't know (care) other
                        // information of the response, e.g. mimetype, content-type, etc.
                        //
                        // The next handler should be responsible to handle 'static' files
                        // just generated.
                        fs.writeFile(that.dst, result, 'utf8', that.next);
                    });
                });
            } catch (err){
                logger.error("[Compiler] compile err: ", err);
                logger.error(err.stack);
                return that.next(err);
            }
        });
        })(this);
    };

    this.process = function() {
        (function(that){
        fs.stat(that.dst, function(err, stat){
            if (err && 'ENOENT' != err.code){
                logger.error("[Compiler] dst stat error: code='%s'", err.code);
                logger.error(err);
                that.next(err);
            } else if (err){
                // We depend on compile() to detect missing src.
                logger.trace("[Compiler] dst not found");
                that.compile();
            } else {
                logger.trace("[Compiler] before comp time");
                that.compareTime(stat);
            }
        });
        })(this);
    };

    this.compareTime = function (dstStat){
        var deps = this.middleware.dependencies(this.src) || [];
        deps = deps.slice(0);
        deps.push(this.src);

        (function(that){
        async.detect(
            deps, 
            function(item, callback){
                fs.stat(item, function(err, stat){
                    if(err){
                        // We depend on compile() to detect missing src.
                        // If there wree error, repeatly compile sounds like reasonable.
                        logger.error(err);
                        callback(true);
                    } else {
                        callback(stat.mtime > dstStat.mtime);
                    }
                });
            },
            function(result){
                if(result){
                    that.compile();
                } else {
                    that.next();
                }
            }
        );
        })(this);

    };
}


