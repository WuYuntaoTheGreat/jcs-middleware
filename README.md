<!-- vim: set et ai nu ts=4 sw=4 cc=80: -->

                      ____._________   _________                   
                     |    |\_   ___ \ /   _____/                   
                     |    |/    \  \/ \_____  \                    
                 /\__|    |\     \____/        \                   
                 \________| \______  /_______  /                   
                                   \/        \/                    
            .__    .___  .___.__                                       
      _____ |__| __| _/__| _/|  |   ______  _  _______ _______   ____  
     /     \|  |/ __ |/ __ | |  | _/ __ \ \/ \/ /\__  \\_  __ \_/ __ \ 
    |  Y Y  \  / /_/ / /_/ | |  |_\  ___/\     /  / __ \|  | \/\  ___/ 
    |__|_|  /__\____ \____ | |____/\___  >\/\_/  (____  /__|    \___  >
          \/        \/    \/           \/             \/            \/ 

jcs-middleware
==============

Jade, CoffeeScript, Stylus middleware for Express.js

Installation
============

Use [npm](www.npmjs.org) to install jcs-middleware:

    npm install jcs-middleware

Usage
=====

## In Express app.js

    app.use('/', require('jsc-middleware')(options));

    app.use('/', express.static(path.join(__dirname, 'public')));

**WARNING**: jcs middleware *MUST* go *BEFORE* static middleware, because it
depends on static middleware to render the compiled js/css/html files.

## Options:
 
**Global options:**

     debug          Output debugging information.
     compress       Uglify the output, all of them.
     force          Force compile every time.
     staticRoot     The root directory of the static files.
     urlBase        The base url prefix, which should point to <staticRoot>

**Coffee-script options:**

     coffeeSrc      Source directory used to find .coffee files.
     coffeeDst      Destination directory where the .js files are stored.
     bare           Compile JavaScript without the top-level function safty
                    wrapper.
     encodeSrc      Encode CoffeeScript source file as base64 comment in
                    compiled JavaScript.

**Stylus options:**

     stylusSrc      Source directory used to find .styl files.
     stylusDst      Destination directory where the .css files are stored.

**Jade options:**

     jadeSrc        Source directory used to find .jade files.
     jadeDst        Destination directory where the .js files are stored.
     jadeStatics    Hash map used to generate jade pages.

If any of the **xxxSrc** options is ommit, that feature will be turned off.

File Path
=========

Say you have a express website at 

    http://yourdomain.com/yourapp

Which is located in your server's directory:

    /path/to/yourapp

In this app, you store all the static files in *public* directory, which
means, all access to

    http://yourdomain.com/yourapp/XXX

goes to

    /path/to/yourapp/public/XXX

Then, you have folder for stylus source files,

    /path/to/yourapp/stylus

and you want put the generated css files be put into directory:

    /path/to/yourapp/public/css

So that anyone can access those css files from url 

    http://yourdomain.com/yourapp/css/*.css

In this scenario:

* **urlBase** is    */yourapp*
* **staticRoot** is */path/to/yourapp/public*
* **stylusSrc** is  */path/to/yourapp/stylus*
* **stylusDst** is  */path/to/yourapp/public/css*

for example:

    +-- path
       +-- to
          +-- yourapp
             +-- public (staticRoot)
             |  +-- ...
             |  +-- css (stylusDst)
             |     +-- ...
             |     +-- XXX.css   <--------+
             |                            |
             +-- stylus (stylusSrc)       | compile to
                +-- ...                   |
                +-- XXX.styl      --------+



The same with coffee and jade options.

Generator
=========

jcs-middleware also comes with a command line tool to generate web application
from template; just like express-generator.

To use this generator, you may need to install a copy of jcs-middleware
globally:
    npm install -g jcs-middleware

##Usage:

    Usage: jcs [options] [dir]
  
    Options:
  
      -h, --help             output usage information
      -V, --version          output the version number
      -f, --force            Force copy template files.
      -n, --name             The name of the web application, default is
                             folder name.
      -t, --template <path>  The template directory, can be ommitted. 


License
=======

MIT (http://www.opensource.org/licenses/mit-license.php)

