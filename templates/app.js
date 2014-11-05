// vim: set ai et nu ts=4 sw=4 cc=100:
//

var express     = require('express')
  , session     = require('express-session')
  , path        = require('path')
  , logger      = require('morgan')
  , cookieParser= require('cookie-parser')
  , bodyParser  = require('body-parser')
  , appConfig   = require('./appConfig')
  ;

require('coffee-script/register');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

// app use chain
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(session({
    secret: appConfig.sessionSecret,
    saveUninitialized: true,
    resave: true,
    cookie: {
        secure: false,
        maxAge: appConfig.sessionAge
    }
}));

// jcs plugin.
var jcsRoot = path.join(__dirname, 'public', 'jcs');
var jcsSource = path.join(__dirname, 'views', 'jcs'); 

app.use(appConfig.prefix, require('jcs-middleware')({
    debug:          appConfig.debugMode,
    compress:       !appConfig.debugMode,
    staticRoot:     path.join(__dirname, 'public'),
    urlBase:        appConfig.prefix,
    
    coffeeSrc:      jcsSource,
    coffeeDst:      jcsRoot,

    stylusSrc:      jcsSource,
    stylusDst:      jcsRoot,

    jadeSrc:        jcsSource,
    jadeDst:        jcsRoot,
    jadeStatics:    {
        appConfig: appConfig,
        renderMode: 'static'
    }
}));

// Static plugin. Must be after jcs plugin.
app.use(appConfig.prefix, express.static(path.join(__dirname, 'public')));

// If prefixed, redirect root to prefixed dir.
app.use('/', function(req, res, next){
    if (appConfig.prefix && appConfig.prefix !== '/' && req.path === '/'){
        res.redirect(appConfig.prefix);
    } else {
        next();
    }
});

////////////////////////
// Here goes the routing
////////////////////////
app.use(appConfig.prefix, require('./routes/index'));


// catch 404 and forward to error handler
app.use(function(req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});

// error handlers
(function(debugMode){
    app.use(function(err, req, res, next) {
        res.status(err.status || 500);
        res.render('error', {
            message: err.message,
            error: debugMode ? err : {}
        });
    });
})(appConfig.debugMode);

module.exports = app;

