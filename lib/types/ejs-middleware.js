/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */
var logger          = require('nice-logger').logger
  , ejs             = require('ejs')
  ;

function Middleware(options){
    this.name = 'Ejs Middleware';
    this.dependencyMap = {};

    options.ejsStatics = options.ejsStatics || {};

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
            filename: srcPath,
            compileDebug: options.debug,
            client: true,
            debug: options.debug,
            delimiter: options.ejsDelimiter || '%',
            strict: !!options.ejsDelimiter,
            rmWhitespace: !options.debug
        };

        // TODO: ejs dependency map.
        logger.debug("rendering %s", srcPath);

        callback(ejs.render(str, options.ejsStatics, opts));
    };

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
