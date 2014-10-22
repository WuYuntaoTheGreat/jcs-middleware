#!
# jcs-middleware Copyright(c) 2014 Wu Yuntao
# https://github.com/WuYuntaoTheGreat/jcs-middleware
# Released under the MIT License.
# vim: set et ai ts=4 sw=4 cc=100 nu:
#

logger  = require("nice-logger").logger
assert  = require "assert"
fs      = require "fs"
JcsConstructor = require "../index"

describe "The test for jcs middleware", ->
    describe "# General test", ->
        logger.info fs.statSync(__filename).mtime.constructor

