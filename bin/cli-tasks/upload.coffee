Logger = require '../../lib/logger'
StaticFarmUploader = require '../../lib/uploader'
Q = require 'q'
fs = require 'fs'
path = require 'path'
filesize = require 'filesize'

Q.longStackSupport = false

class UploadTask

    ArrayPush = Array::push
    allowedExtensions = ['.js', '.css', '.png', '.jpg']
    _stat = Q.denodeify fs.stat
    _readdir = Q.denodeify fs.readdir

    constructor: (sources, @options) ->
        @uploader = new StaticFarmUploader()

        # @startSnapshot = process.memoryUsage().heapUsed

        Q.all(sources.map @getFileList.bind @)
            # flatten list
            .then((arr) -> arr.reduce (a, b) -> a.concat b)
            # process file list
            .then(@process.bind @)

    getFileList: (input) ->
        promise = _stat input
        return promise.then (infos) =>
            if infos.isDirectory()
                return @readdir input
            else
                return [input]

    readdir: (dir) ->
        promise = _readdir dir
        dirname = dir.replace /\/$/, ''
        return promise.then (files) =>
            return files
                .filter(@isAllowedExtension.bind @)
                .map((f) -> "#{dirname}/#{f}")

    isAllowedExtension: (file) ->
        !!~allowedExtensions.indexOf path.extname(file)

    process: (fileList) ->
        unqueue = () =>
            if fileList.length
                f = fileList.shift()
                @upload(f).then(unqueue)
            # else
            #     finalSnapshot = process.memoryUsage().heapUsed
            #     diff = finalSnapshot - @startSnapshot
            #     percent = ((finalSnapshot / @startSnapshot) - 1) * 100
            #     console.log 'First heap:', @startSnapshot
            #     console.log 'Final heap:', finalSnapshot
            #     console.log 'Difference: %s (+%s%)', diff, percent | 0
        unqueue()

    upload: (file) ->
        $logger = Logger
        $cursor = $logger.cursor

        fileSize = filesize fs.statSync(file).size
        startTime = +new Date()

        $cursor.blue()
        $logger.clear().writeln "⇪  Deposing #{file} (#{fileSize})"
        $cursor.grey()

        onSuccess = (asset) ->
            elapsedTime = +new Date() - startTime
            $cursor.green()
            $logger.clear().writeln "✔  url: #{asset.url}, hash: #{asset.hash} (#{elapsedTime}ms)\n"
            $cursor.reset()

        onError = (err) ->
            $cursor.yellow()
            $logger.write "  >> #{err}"
            $cursor.reset()

        return @uploader.upload(file).then(onSuccess).catch(onError)

module.exports = (args) -> new UploadTask args
