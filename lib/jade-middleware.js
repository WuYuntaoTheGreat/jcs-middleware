/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */
var logger          = require('nice-logger').logger
  , jade            = require('jade')
  , JadeInheritance = require('jade-inheritance')
  ;

function Middleware(options){
    this.dependencyMap = {};

    options.jadeStatics = options.jadeStatics || {};

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
            doctype: 'html',
            pretty: !options.compress,
            debug: false,
            compileDebug: options.debug
        };

        for (var k in options.jadeStatics){
            opts[k] = options.jadeStatics[k];
        }

        inheritance = new JadeInheritance(srcPath);
        logger.debug("rendering %s", srcPath);
        this.dependencyMap[srcPath] = inheritance.files;
        callback(jade.render(str, opts));
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

