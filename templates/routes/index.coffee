# vim: set ai et nu ts=4 sw=4 cc=100:
appConfig   = require '../appConfig'
express     = require 'express'

router = express.Router()

router.get /^\//, (req, res) ->
    res.render '/index', {}

module.exports = router

