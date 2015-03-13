/*!
 * jcs-middleware Copyright(c) 2014 Wu Yuntao
 * https://github.com/WuYuntaoTheGreat/jcs-middleware
 * Released under the MIT License.
 * vim: set et ai ts=4 sw=4 cc=100 nu:
 */

function AlterLogger(){
    this.debug = function(){
    };

    this.trace = function(){

    };

    this.error = function(){

    };
}



module.exports = { logger: new AlterLogger() };
