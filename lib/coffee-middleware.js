/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

var logger          = require('graceful-logger')
  , coffee          = require('coffee-script')
  , path            = require('path')
  , uglifyjs        = require('uglifyjs')
  , convertSourceMap= require('convert-source-map')
  ;

function Middleware(options){
    /**
     * Compiles the given string source.
     *
     * @parem {String} str The source string to compile.
     * @param {String} srcPath, The file path of the source file.
     * @param {String} dstPath, The file path of the target file.
     * @param {Function} callback, The callback function to gather the compile result (as String)
     */
    this.compile = function(str, srcPath, dstPath, callback){
        var opts = {
            bare: options.bare,
            filename: path.basename(srcPath),
            sourceMap: true
        };
        var compiledObj = coffee.compile(str, opts);
        logger.info("rendering %s", srcPath);
        var sourceMapObj = {
            version: 3,
            file: path.basename(dstPath),
            source: [path.basename(srcPath)],
            names: [],
            mapping: JSON.parse(compiledObj.v3SourceMap).mappings
        };

        var compiledJs = compiledObj.js;
        // Optionally, append the comment to our source
        if (options.encodeSrc && !options.compress) {
            // Translate the sourcemap into a base64 comment
            var sourceMapStr = convertSourceMap.fromObject(sourceMapObj).toComment();
            compiledJs += '\n' + sourceMapStr;
        }
        if (options.compress){
            compiledJs = uglifyjs.minify(compiledJs, {fromString: true}).code;
        }
        callback(compiledJs);
    };

    /**
     * Returns the dependencyMap of given 'srcPath' file.
     *
     * @param {String} srcPath
     * @return an array of files 'srcPath' dependents on.
     */
    this.dependencies = function(srcPath){
        return null;
    };
}

module.exports = function(options){
    return new Middleware(options);
};
