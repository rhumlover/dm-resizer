Logger = require './logger'
StaticFarmUploader = require '../uploader'
Q = require 'q'
fs = require 'fs'
path = require 'path'

module.exports = UploadTask = (args, options) ->

    uploader = new StaticFarmUploader()
    arrayPush = Array::push
    allowedExtensions = ['.js', '.css', '.png', '.jpg']

    isAllowedExtension = (file) ->
        return !!~allowedExtensions.indexOf path.extname(file)

    fileList = []
    for arg in args
        do (arg) ->
            file = fs.realpathSync arg
            if not fs.existsSync file then return

            if fs.statSync(file).isDirectory()
                dirFiles = fs.readdirSync(file)
                    .filter(isAllowedExtension)
                    .map((i) ->
                        return {
                            displayName: arg.replace(/\/$/, '') + '/' + i
                            fullPath: fs.realpathSync "#{file}/#{i}"
                        }
                    )

                fileList.push.apply fileList, dirFiles
            else
                fileList.push {
                    displayName: arg
                    fullPath: file
                }

    if fileList.length
        uploadFile = (file) ->
            defer = Q.defer()

            Logger.cursor.grey()
            loading = Logger.loading "⇪  Deposing #{file.displayName}"
            loading.start()
            uploader.upload(file.fullPath)
                .done((asset) ->
                    loading.stop()
                    Logger.cursor.green()
                    Logger.clear().writeln "⇪  Deposing #{file.displayName} ✔"
                    Logger.cursor.reset()
                    Logger.writeln "   url: #{asset.url}, hash: #{asset.hash}\n"
                    defer.resolve asset
                )
            defer.promise

        queueIndex = 0
        unqueue = (index) ->
            if f = fileList[index]
                uploadFile(f).done () -> unqueue ++queueIndex

        unqueue 0

    return