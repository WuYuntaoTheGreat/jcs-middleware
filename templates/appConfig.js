// vim: set ai et nu ts=4 sw=4 cc=100:
//

var path    = require('path')
  , app = require('express')()
  ;

var theConfig = {};

try{
    theConfig = require(path.join(__dirname, 'theConfig.json'));
} catch(err){
    if (err.code != 'MODULE_NOT_FOUND') {
        console.error(err);
    }
}

theConfig.debugMode     = app.get('env') === 'development';
theConfig.jadeStatics   = theConfig.jadeStatics || {};
theConfig.prefix        = theConfig.prefix || '/';
theConfig.sessionAge    = theConfig.sessionAge || 7 * 24 * 3600 * 1000;
theConfig.sessionSecret = 'jcs secret';

module.exports = theConfig;

