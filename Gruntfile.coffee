#
# * dm-resizer
# * https://github.com/rhumlover/dm-resizer
# *
# * Copyright (c) 2014 Thomas Le Jeune
# * Licensed under the MIT license.
#
"use strict"

module.exports = (grunt) ->

    grunt.initConfig {
        coffeelint:
            options:
                'configFile': 'coffeelint.json'
            app: [
                "Gruntfile.coffee"
                "tasks/{,*/}*.coffee"
                "bin/{,*/}*.coffee"
                "lib/{,*/}*.coffee"
            ]

        clean:
            test: ["tmp/*"]

        copy:
            test:
                src: 'test/assets/index.html'
                dest: 'tmp/index.html'

        resizer:
            test:
                src: [
                    'test/assets/claquos.jpg'
                ]
                update: 'tmp/index.html'
    }

    grunt.loadTasks "tasks"

    # These plugins provide necessary tasks.
    grunt.loadNpmTasks "grunt-contrib-clean"
    grunt.loadNpmTasks "grunt-contrib-copy"
    grunt.loadNpmTasks "grunt-coffeelint"

    # Whenever the "test" task is run, first clean the "tmp" dir, then run this
    # plugin's task(s), then test the result.
    grunt.registerTask "test", [
        "clean:test"
        "copy:test"
        "resizer:test"
    ]

    # By default, lint and run all tests.
    grunt.registerTask "default", [
        "coffeelint"
        "test"
    ]
    return
