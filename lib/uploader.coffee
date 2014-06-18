Asset = require './asset'
DB = require './database'
Q = require 'q'
fs = require 'fs'
http = require 'http'
path = require 'path'
querystring = require 'querystring'

class StaticFarmUploader

    DEFAULT_DB_PATH = "#{__dirname}/../db/#{process.env['USER']}.json"
    RESIZER_HOST = 's1.dmcdn.net'

    constructor: (options = {}) ->
        @options = options
        {db,timeout} = options

        if db isnt false
            dbFile = path.resolve "#{db}"
            if not fs.existsSync dbFile then dbFile = DEFAULT_DB_PATH
            @db = new DB dbFile
        @

    invalidate: (hash) ->
        return unless @db?
        @db.remove hash
        @

    upload: (file) ->
        self = @
        db = @db
        def = Q.defer()

        basename = path.basename file
        content = fs.readFileSync(file).toString 'base64'
        finalContent = querystring.stringify { payload: content }

        extension = path.extname basename
        if ~['.js', '.css'].indexOf extension
            uploadType = extension.slice 1
        else if ~['.png', '.jpg', '.gif'].indexOf extension
            uploadType = 'image'
        else
            uploadType = 'data'

        options =
            agent: false
            host: 'depot.dmcdn.net'
            port: '80'
            path: "/#{uploadType}"
            method: 'POST'
            headers:
                'Content-Type': 'application/x-www-form-urlencoded'
                'Content-Length': finalContent.length

        if @options.timeout?
            timeout = setTimeout () ->
                def.reject 'Depot request timed out'
            , (@options.timeout)

        req = http.request options, (res) =>
            clearTimeout timeout

            _statusCode = res.statusCode
            if 200 < res.statusCode > 203
                _filePath = path.resolve file
                _options = JSON.stringify options
                def.reject "Request returned a #{_statusCode} status:\nFile: #{_filePath}\nOptions: #{_options}"
                return

            body = []
            res.setEncoding 'utf8'
            res.on 'data', (chunk) => body.push "#{chunk}"
            res.on 'end', =>
                [uploadedFile,hash] = body.join('').split('#')
                asset = {
                    file:
                        basename: basename
                        inputpath: file
                        fullpath: path.resolve file
                    user: process.env['USER']
                    url: "#{RESIZER_HOST}/#{uploadedFile}"
                    timestamp: +new Date()
                    hash: hash
                }
                if not /^http/.test asset.url
                    asset.url = 'http://' + asset.url

                if db?
                    db.set(basename, asset)
                        .then(
                            (_asset) -> def.resolve _asset,
                            (err) -> def.reject err
                        )
                else
                    def.resolve asset

        req.on 'error', (e) ->
            def.reject 'An error occured:', e.message

        req.end finalContent

        return def.promise

    list: () ->
        return @db.findAll () -> true

module.exports = StaticFarmUploader
