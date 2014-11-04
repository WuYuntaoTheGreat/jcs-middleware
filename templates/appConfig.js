// vim: set ai et nu ts=4 sw=4 cc=100:
//

var path    = require('path')
  , app = require('express')()
  ;

var CONF = {};

try{
    CONF = require(path.join(__dirname, 'CONF.json'));
} catch(err){
    if (err.code != 'MODULE_NOT_FOUND') {
        console.error(err);
    }
}

CONF.prefix         = CONF.prefix          || '/';
CONF.sessionAge     = CONF.sessionAge      || 7 * 24 * 3600 * 1000;
CONF.sessionSecret  = CONF.sessionSecret   || 'jcs secret';
CONF.debugMode      = app.get('env') === 'development';
CONF.renderMode     = 'static';

module.exports = CONF;

