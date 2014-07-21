ansi = require 'ansi'
cursor = ansi process.stdout

module.exports = {
    cursor: cursor

    clear: () ->
        cursor.horizontalAbsolute(0).eraseLine()
        @

    clearAt: (x=1, y=1) ->
        cursor.goto(x, y).horizontalAbsolute(0).eraseLine()
        @

    write: (msg = '') ->
        cursor.write msg
        @

    writeln: (msg = '') ->
        cursor.write msg + "\n"
        @

    writeAt: (msg = '', x=1, y=1) ->
        cursor.goto(x, y).write msg
        @

    writelnAt: (msg = '', x=1, y=1) ->
        cursor.goto(x, y).write msg + "\n"
        @

    steps: (n) ->
        self = @
        currentStep = 0

        _write = (i=0) =>
            res = ['[']
            for step in [0...n]
                res.push if step < i then '◼' else '◻'
            res.push ']'
            @write res.join ''

        _write()
        return {
            next: () ->
                self.clear()
                _write ++currentStep
        }

    progress: (maxVal) ->
        self = @

        _write = (percent=0) =>
            res = ["#{percent}% done"]
            for step in [0...percent/10]
                res.push '.'
            @write res.join ''

        _write()
        return {
            update: (val) ->
                percent = parseInt (val/maxVal) * 100, 0
                self.clear()
                _write percent
        }

    loading: (prefix) ->
        self = @
        interval = null
        return {
            start: () ->
                cursor.hide()
                symbols = ['◐', '◓', '◑', '◒']
                step = 0
                sLen = symbols.length
                interval = setInterval () ->
                    self.clear()
                    self.write (if prefix then prefix else '') + ' ' + symbols[++step%sLen]
                , 300

            stop: () ->
                cursor.show()
                clearInterval interval
        }
}