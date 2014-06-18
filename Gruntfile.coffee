#
# * grunt-staticfarm
# * https://github.com/rhumlover/grunt-staticfarm
# *
# * Copyright (c) 2014 Thomas Le Jeune
# * Licensed under the MIT license.
#
"use strict"

module.exports = (grunt) ->

    grunt.initConfig {
        coffeelint:
            app: [
                "Gruntfile.coffee"
                "tasks/*.coffee"
            ]

        clean:
            tests: ["tmp"]

        resizer:
            test:
                files: [
                    'test/assets/claquos.jpg'
                ]
                dest: 'test/assets/index.html'
    }

    grunt.loadTasks "tasks"

    # These plugins provide necessary tasks.
    grunt.loadNpmTasks "grunt-contrib-clean"
    grunt.loadNpmTasks "grunt-coffeelint"

    # Whenever the "test" task is run, first clean the "tmp" dir, then run this
    # plugin's task(s), then test the result.
    grunt.registerTask "test", [
        "clean"
        "resizer"
    ]

    # By default, lint and run all tests.
    grunt.registerTask "default", [
        "jshint"
        "test"
    ]
    return
