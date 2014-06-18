Datastore = require 'nedb'
Q = require 'q'
fs = require 'fs'

class DB

    _noop = ->
    _resolve = (err, res) ->
        if err? then @reject err else @resolve res

    constructor: (filename) ->
        @db = new Datastore {filename, autoload: true}

    get: (key) ->
        def = Q.defer()
        @db.findOne {name:key}, _resolve.bind(def)
        def.promise

    set: (key, asset) ->
        def = Q.defer()
        asset['name'] = key
        @db.insert asset, _resolve.bind(def)
        def.promise

    has: (key) ->
        def = Q.defer()
        @db.findOne {name:key}, _resolve.bind(def)
        def.promise

    remove: (hash) ->
        def = Q.defer()
        @db.remove {hash:key}, {multi:true}, _resolve.bind(def)
        def.promise

    find: (ob) ->
        def = Q.defer()
        @db.findOne ob, _resolve.bind(def)
        def.promise

    findAll: (ob) ->
        def = Q.defer()
        @db.find ob, _resolve.bind(def)
        def.promise

module.exports = DB