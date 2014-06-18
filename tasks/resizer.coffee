StaticFarmUploader = require '../lib/uploader'
Logger = require '../lib/logger'
path = require 'path'

walk = (arr, itemFn, endFn) ->
    pos = 0
    cb = (err, result) -> process ++pos
    process = () ->
        item = arr[pos]
        if item? then itemFn(item, cb)
        else endFn()
    process()


module.exports = (grunt) ->

    grunt.registerMultiTask 'resizer', 'Uploads assets to resizer depot', () ->
        done = @async()
        _logger = Logger
        _cursor = _logger.cursor

        options = @options {}
        {db} = options

        [taskParameters] = @files
        {src,html} = taskParameters

        uploader = new StaticFarmUploader {db}
        uploadedAssets = []

        replaceHTMLReference = (previousUrl, cdnUrl, inFiles) ->
            relativePath = previousUrl.replace 'dist', ''
            regex_css = new RegExp "url\\([./]*#{relativePath}\\)", "g"
            regex = new RegExp relativePath, "g"

            inFiles.forEach (f) ->
                type = path.extname f
                content = grunt.file.read f
                replacedContent = false

                if type is '.css'
                    if regex_css.test content
                        replacedContent = content.replace regex_css, "url(#{cdnUrl})"
                else
                    if regex.test content
                        replacedContent = content.replace regex, cdnUrl

                replacedContent and grunt.file.write f, replacedContent

        onEachSource = (fileObj, sourceDoneCb) ->
            {src,update} = fileObj
            files = grunt.file.expand {}, src

            onEachFile = (filepath, fileDoneCb) ->
                loading = _logger.loading "⇪  Deposing #{filepath}"
                _cursor.grey()
                loading.start()
                startTime = +new Date()

                promise = uploader.upload filepath

                onSuccess = (asset) ->
                    uploadedAssets.push asset
                    elapsedTime = +new Date() - startTime
                    loading.stop()
                    _cursor.green()
                    _logger.clear().writeln "⇪  Deposing #{asset.file.inputpath} ✔ (#{elapsedTime}ms)"
                    _cursor.reset()
                    _logger.writeln "   url: #{asset.url}, hash: #{asset.hash}\n"

                    if update?
                        do () ->
                            try
                                files = grunt.file.expand {}, update
                                replaceHTMLReference asset.file.inputpath, asset.url, files
                            catch e
                                grunt.log.error e
                            fileDoneCb()
                    else
                        fileDoneCb()

                onError = (message) ->
                    grunt.log.writeln ('>> ' + message)['yellow']
                    loading.stop()
                    fileDoneCb()

                if promise? then promise.then onSuccess, onError
                return

            walk files, onEachFile, sourceDoneCb

        walk @files, onEachSource, done
