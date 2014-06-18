Logger = require './logger'
StaticFarmUploader = require '../uploader'
Q = require 'q'
fs = require 'fs'
path = require 'path'

arrayPush = Array::push
allowedExtensions = ['.js', '.css', '.png', '.jpg']
uploader = new StaticFarmUploader()

isAllowedExtension = (file) ->
    return !!~allowedExtensions.indexOf path.extname(file)

getFileList = do ->
    _readdir = (input, fullPath, cb) ->
        fs.readdir fullPath, (err, files) ->
            dirFiles = files.filter(isAllowedExtension).map (i) ->
                return {
                    displayName: input.replace(/\/$/, '') + '/' + i
                    fullPath: "#{fullPath}/#{i}"
                }
            cb dirFiles

    return (input) ->
        fullPath = path.resolve input
        def = Q.defer()
        fs.stat fullPath, (err, infos) ->
            if err
                def.reject err
                return

            if infos.isDirectory()
                _readdir input, fullPath, (files) -> def.resolve files
            else
                def.resolve [{
                    displayName: input
                    fullPath: fullPath
                }]
        def.promise

# uploadFile = (file) ->
#     def = Q.defer()

#     Logger.cursor.grey()
#     loading = Logger.loading "⇪  Deposing #{file.displayName}"
#     loading.start()
#     uploader.upload(file.fullPath)
#         .done((asset) ->
#             loading.stop()
#             Logger.cursor.green()
#             Logger.clear().writeln "⇪  Deposing #{file.displayName} ✔"
#             Logger.cursor.reset()
#             Logger.writeln "   url: #{asset.url}, hash: #{asset.hash}\n"
#             def.resolve asset
#         )
#     def.promise

uploadFile = (file) ->
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

module.exports = UploadTask = (args) ->
    finished = Q.defer()
    fileList = []

    for arg, index in args
        do (index) ->
            getFileList(arg).done (files) ->
                arrayPush.apply fileList, files
                finished.notify index

    finished.promise.progress (index) ->
        if index is args.length-1
            if fileList.length
                queueIndex = 0
                unqueue = (index) ->
                    if f = fileList[index]
                        uploadFile(f).done () -> unqueue ++queueIndex
                unqueue 0
    return