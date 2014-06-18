Logger = require './logger'
DB = require '../database'
Q = require 'q'
fs = require 'fs'
path = require 'path'

module.exports = ListTask = (args) ->
    DEFAULT_DB_PATH = __dirname + '/../../db/staticfarm.json'

    console.log process.env['USER']

    db = new DB path.resolve DEFAULT_DB_PATH
    db.findAll().done (list) ->
        simpleList = {}
        list.forEach (record) ->
            # console.log record
            # if _saved = simpleList[record.name]
            #     _saved.push
    return