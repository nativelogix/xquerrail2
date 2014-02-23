/*
 * Licensed under the MIT license.
 */

'use strict';

module.exports = function(grunt) {

  // Actually load this plugin's task(s).
  // grunt.loadTasks('tasks');

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');

  // Project configuration.
  grunt.initConfig({
    env: grunt.file.readJSON("env.json"),
    jshint: {
      all: [
        'Gruntfile.js',
        'tasks/*.js'
      ],
      options: {
        jshintrc: '.jshintrc',
      },
    },
    watch: {
      scripts: {
        files: ['src/**/*-domain.xml'],
        tasks: ['refresh_cache'],
        options: {
          spawn: false,
        },
      },
    },
    refresh_cache: {
      all: {
        url: '<%= env.url %>/initialize.xqy'
      }
    }
  });

  grunt.registerMultiTask('refresh_cache', 'Refresh XQuerrail cache', function() {
    grunt.verbose.writeln('*** Refresh XQuerrail cache ***]');
    var request = require('request');
    var url = this.data.url;
    var req = request.get(url, function(err, response, body) {
      if (response.statusCode === 200) {
        grunt.log.ok('Cache refreshed');
      } else {
        grunt.fail.warn('Error status code: ' + response.statusCode);
        grunt.verbose.writeln(body);
        // error(err);
      }
    });
  });

  // Whenever the "test" task is run, first clean the "tmp" dir, then run this
  // plugin's task(s), then test the result.
  // grunt.registerTask('test', ['clean', 'xray_runner', 'nodeunit']);

  // By default, lint and run all tests.
  grunt.registerTask('default', ['jshint']);

};
