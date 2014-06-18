Dirty = require 'dirty'
fs = require 'fs'

DB_PATH = './test/database_test.json'

fs.unlinkSync DB_PATH if fs.existsSync DB_PATH
fs.openSync DB_PATH, 'w'

db = Dirty DB_PATH
db.on 'load', () ->
    db.set 'testA', {'a':'a'}
    db.set 'testB', {'b':'b'}

    db.forEach (key, val) ->
        console.log "Key:#{key}, Val:#{val}"

    console.log '\n'
    console.log 'Removing testA'
    console.log '--------------------'
    db.rm 'testA'

    db.forEach (key, val) ->
        console.log "Key:#{key}, Val:#{val}"
