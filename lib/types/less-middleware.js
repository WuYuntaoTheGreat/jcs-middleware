/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */
var logger          = require('../logger').logger
  , less            = require('less')
  , path            = require('path')
  ;

function Middleware(options){
    this.name = 'Stylus Middleware';
    this.dependencyMap = {};

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
            paths: options.lessPaths || [],
            filename: srcPath,
            compress: !options.debug
        };

        // TODO: ejs dependency map.
        logger.debug("rendering " + srcPath);

        less.render(str, opts, function(err, output){
            if(err){
                throw err;
            } else {
                callback(output.css);
            }
        });
    }

    /**
     * Returns the dependencyMap of given 'srcPath' file.
     *
     * @param {String} srcPath
     * @return an array of files 'srcPath' dependents on.
     */
    this.dependencies = function(srcPath){
        return this.dependencyMap[srcPath];
    };
}

module.exports = function(options){
    return new Middleware(options);
};

