#! /usr/bin/env node
fs = require 'fs'
path = require 'path'
program = require 'commander'

# ------------------------
# CLI INTERFACE
# ------------------------
list = (val) -> val.split ','

program
    .version('0.1.0')
    .usage('[options] <file ...>')
    .option('-d, --depose <items>', 'depose file(s) to dmcdn')
    .option('-i, --invalidate', 'invalidate a file by providing its hash')
    .option('-l, --list', 'list deposed files')
    .option('-u, --user', 'act as user')
    .option('-db, --database', 'use a specific file as database')
    .parse(process.argv)

if program.invalidate then require('./cli-tasks/invalidate')(program.args)
else if program.list then require('./cli-tasks/list')(program.args)
else require('./cli-tasks/upload-async-module')(program.args, {user:program.user, db:program.db})

exports.staticfarm = {}