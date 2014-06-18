Logger = require './logger'
StaticFarmUploader = require '../uploader'
Q = require 'q'
fs = require 'fs'
path = require 'path'

ArrayPush = Array::push

class UploadTask

    constructor: (args, @options) ->
        @uploader = new StaticFarmUploader()
        finished = Q.defer()
        promise = finished.promise
        fileList = []

        for arg, index in args
            do (index) =>
                @getFileList(arg).done (files) ->
                    ArrayPush.apply fileList, files
                    finished.notify index

        promise.progress (index) =>
            if index is args.length-1
                if fileList.length
                    queueIndex = 0
                    unqueue = (index) =>
                        if f = fileList[index]
                            @uploadFile(f).done () -> unqueue ++queueIndex
                    unqueue 0

    allowedExtensions: ['.js', '.css', '.png', '.jpg']

    isAllowedExtension: (file) ->
        !!~@allowedExtensions.indexOf path.extname(file)

    readdir: (input, fullPath, cb) ->
        fs.readdir fullPath, (err, files) =>
            dirFiles = files.filter(@isAllowedExtension.bind(@)).map (i) ->
                return {
                    displayName: input.replace(/\/$/, '') + '/' + i
                    fullPath: "#{fullPath}/#{i}"
                }
            cb dirFiles
        @

    getFileList: (input) ->
        fullPath = path.resolve input
        def = Q.defer()
        fs.stat fullPath, (err, infos) =>
            if err
                def.reject err
                return

            if infos.isDirectory()
                @readdir input, fullPath, (files) -> def.resolve files
            else
                def.resolve [{
                    displayName: input
                    fullPath: fullPath
                }]
        def.promise

    uploadFile: (file) ->
        def = Q.defer()
        loading = Logger.loading "⇪  Deposing #{file.displayName}"
        asset = {
            url: 'toto'
            hash: '#fOn_9'
        }
        Logger.cursor.grey()
        loading.start()
        startTime = +new Date()
        setTimeout () ->
            loading.stop()
            Logger.cursor.green()
            elapsedTime = +new Date() - startTime
            Logger.clear().writeln "⇪  Deposing #{file.displayName} ✔ (#{elapsedTime}ms)"
            Logger.cursor.reset()
            Logger.writeln "   url: #{asset.url}, hash: #{asset.hash}\n"
            def.resolve {}
        , 2000
        def.promise

module.exports = (args) ->
    new UploadTask args