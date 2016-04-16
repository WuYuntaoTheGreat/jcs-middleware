/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

function Logger(level){
    level = level ? level : 0;
    this.trace = this.debug = this.info = this.warn = this.error = function(){};
    if(level > 4)
        this.trace  = console.log;
    if(level > 3)
        this.debug  = console.log;
    if(level > 2)
        this.info   = console.log;
    if(level > 1)
        this.warn   = console.log;
    if(level > 0)
        this.error  = console.error;
}

module.exports = { "logger": new Logger(2) };
