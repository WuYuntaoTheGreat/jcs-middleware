/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */
var logger          = require('nice-logger').logger
  , stylus          = require('stylus')
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
        var style = stylus(str)
            .set('filename', srcPath)
            .set('compress', options.compress)
            ;
        style.options._imports = [];
        delete this.dependencyMap[srcPath];

        (function(that){
            style.render(function(err, css){
                if (err) {
                    logger.error(err);
                    throw err;
                }
                logger.debug("renderinng %s", srcPath);
                that.dependencyMap[srcPath] = [];
                style.options._imports.forEach(function(i){
                    that.dependencyMap[srcPath].push(i.path.replace(/\//g, path.sep));
                });


                logger.trace('==========');
                logger.trace("that.dependencyMap[srcPath]=");
                logger.trace(that.dependencyMap[srcPath]);
                // logger.trace("style.parser.root=\n", style.parser.root.nodes[0].nodes);

                callback(css);
            });
        })(this);
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

