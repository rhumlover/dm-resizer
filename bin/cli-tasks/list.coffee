Logger = require '../../lib/logger'
DB = require '../../lib/database'
Q = require 'q'
fs = require 'fs'
path = require 'path'

module.exports = ListTask = (args) ->
    DEFAULT_DB_PATH = "#{__dirname}/../../db/#{process.env['USER']}.json"

    db = new DB path.resolve DEFAULT_DB_PATH
    db.findAll().done (list) ->
        simpleList = {}
        list.forEach (record) ->
            console.log record
    return