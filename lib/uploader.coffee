Asset = require './asset'
DB = require './database'
Q = require 'q'
fs = require 'fs'
http = require 'http'
path = require 'path'
querystring = require 'querystring'

class StaticFarmUploader

    DEFAULT_TIMEOUT = 5000
    DEFAULT_DB_PATH = path.resolve __dirname, "../db/#{process.env['USER']}.json"
    HOSTS = {
        http: ['s1.dmcdn.net', 's2.dmcdn.net']
        https: ['s1-ssl.dmcdn.net', 's2-ssl.dmcdn.net']
    }

    constructor: (options = {}) ->
        @options = options
        {db,timeout} = options

        if !!~Object.keys(HOSTS).indexOf(@options.protocol) is false
            @options.protocol = 'http'

        if db isnt false
            dbFile = path.resolve "#{db}"
            if not fs.existsSync dbFile then dbFile = DEFAULT_DB_PATH
            @db = new DB dbFile

        return @

    invalidate: (hash) ->
        return unless @db?
        @db.remove hash
        return @

    getHostForAsset: (content) ->
        hash = 0
        lim = content.length
        while lim > 0
            hash = hash * 33 + content.charCodeAt(--lim)
            hash = (hash + (hash >> 5)) & 0x7ffffff
        hosts = HOSTS[@options.protocol]
        return @options.protocol + '://' + hosts[hash % 2]

    upload: (file) ->
        self = @
        db = @db
        def = Q.defer()

        basename = path.basename file
        content_raw = fs.readFileSync(file)
        content_b64 = content_raw.toString 'base64'
        payload = querystring.stringify { payload: content_b64 }

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
                'Content-Length': payload.length

        if @options.timeout?
            timeout = setTimeout () ->
                def.reject 'Depot request timed out'
            , @options.timeout

        req = http.request options, (res) ->
            clearTimeout timeout if timeout?

            _statusCode = res.statusCode
            if 200 < res.statusCode > 203
                _filePath = path.resolve file
                _options = JSON.stringify options
                def.reject "Request returned a #{_statusCode} status:\nFile: #{_filePath}\nOptions: #{_options}"
                return

            body = []
            res.setEncoding 'utf8'
            res.on 'data', (chunk) -> body.push "#{chunk}"
            res.on 'end', ->
                [uploadedFile,hash] = body.join('').split('#')
                cdnUrl = self.getHostForAsset(content_raw.toString()) + '/' + uploadedFile
                asset = {
                    file:
                        basename: basename
                        inputpath: file
                        fullpath: path.resolve file
                    user: process.env['USER']
                    url: cdnUrl
                    timestamp: +new Date()
                    hash: hash
                }

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

        req.end payload
        return def.promise

module.exports = StaticFarmUploader
