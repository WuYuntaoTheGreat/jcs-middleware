// vim: set ai et nu ts=4 sw=4 cc=100:
// This file contains the setup of jcs middleware.
//
// This file was separated from ./app.js because we wants to use
// the jcs config in ./bin/prepare, yet we don't want to start the
// server.

var path        = require('path')
  , appConfig   = require('./appConfig')
  ;

module.exports = require('jcs-middleware')({
    debug:          appConfig.debugMode,
    compress:       !appConfig.debugMode,
    staticRoot:     path.join(__dirname, 'public'),
    urlBase:        appConfig.prefix,

    coffeeSrc:      path.join(__dirname, 'views', 'jcs'),
    coffeeDst:      path.join(__dirname, 'public', 'jcs'),

    stylusSrc:      path.join(__dirname, 'views', 'jcs'),
    stylusDst:      path.join(__dirname, 'public', 'jcs'),

    jadeSrc:        path.join(__dirname, 'views', 'jcs'),
    jadeDst:        path.join(__dirname, 'public', 'jcs'),
    jadeStatics:    {
        appConfig: appConfig,
        renderMode: 'static'
    }
});


