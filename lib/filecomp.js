/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */
var logger          = require('nice-logger').logger
  , fs              = require('fs')
  ;

/**
 * Handle the dependency map.
 * This function should be called after the destination file's state already retrived.
 * @param {fs.State} dstStat The state of the destination file.
 * @param {String[]} deps An array of dependency file names.
 * @param cb Callback collection, should have following members: 
 * onError, onIgnore, onChanged.
 */
function compareDeps(dstStat, deps, cb){
    deps = deps || [];
    logger.trace("Deps=", deps);
    if (deps.length == 0){
        return cb.onIgnore();
    }

    var pending = deps.length;
    var changed = [];
    var errors  = [];


    var thatsAll = function(){
        if (errors && errors.length > 0){
            var bigErr = new Error('');
            for(var i = 0; i < errors.length; i++){
                logger.error("Dependency file '%s' error!", errors[i]);
                bigErr.message += errors[i].message + '\n';
            }
            return cb.onError(bigErr);
        } else if (changed && changed.length > 0){
            for(var i = 0; i < changed.length; i++){
                logger.debug("Dependency file '%s' changed", changed[i]);
            }
            return cb.onChanged(changed);
        } else {
            cb.onIgnore();
        }
        
    };

    deps.forEach(function(dep){
        fs.stat(dep, function(err, stat){
            if(err){
                err.fileName = err.fileName || dep;
                errors.push(err);
            } else if (stat.mtime > dstStat.mtime){
                changed.push(dep);
            }

            --pending || thatsAll();
        });
    });
}

/**
 * Compare the timestamp of source file and it's dependency files agains the destination file.
 * Here, we assume source file exists, and it's state object already retrieved.
 *
 * @param {String} dst Destination filename.
 * @param {String} src Source filename.
 * @param {fs.State} srcStat The file state of source file.
 * @param {String[]} deps Dependency filenames.
 * @param cb Callback collection, should have following members: 
 * onError, onIgnore, onChanged.
 */
function compareTime(dst, src, srcStat, deps, cb){
    fs.stat(dst, function(err, dstStat){
        if (err && 'ENOENT' == err.code){
            return cb.onChanged([src]);
        } else if (err){
            return cb.onError(err);
        } else if (srcStat.mtime > dstStat.mtime){
            return cb.onChanged([src]);
        } else {
            return compareDeps(dstStat, deps, cb);
        }
    });
}

/**
 * Check a destination file path agains it's corresponding source file and dependency files of the
 * source file.
 * <UL>
 * <LI>If the source file does not exist, call onIgnore.
 * <LI>If the destination file does not exist, call onChanged.
 * <LI>If the source file is newer than the destination file, call onChanged.
 * <LI>If one of the source file's dependency files is newer than the destination file, call
 * onChanged.
 * <LI>If error, call onError.
 * <LI>Else, call onIgnore.
 *
 * @param {String} dst Destination filename.
 * @param {String} src Source filename.
 * @param {String[]} deps Dependency filenames.
 * @param cb Callback collection, should have following members: 
 * onError, onIgnore, onChanged.
 */
module.exports = function(dst, src, deps, cb){
    fs.stat(src, function(err, stat){
        if (err && 'ENOENT' == err.code){
            logger.debug("src not found for dst: %s", dstPath);
            return cb.onIgnore();
        } else if (err){
            return cb.onError(err);
        } else {
            return compareTime(dst, src, stat, deps, cb);
        }
    });
}

