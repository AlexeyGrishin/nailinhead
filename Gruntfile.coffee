module.exports = (grunt) ->
  grunt.initConfig {
    coffee:
      dev:
        expand: true
        cwd: "src"
        src: ["**/*.coffee"]
        dest: "src"
        ext: ".js"
      building:
        files:
          "public/js/index.js": ["tools/loading.coffee"]
        options:
          bare: true
      tests:
        expand: true
        cwd: "tests"
        src: ["**/*.coffee"]
        dest: "tests"
        ext: ".js"
    browserify:
      dev:
        files: 
          'public/js/index.js': ["src/**/*.js"]
        options:
          require: true
      test:
        files:
          'public/js/test.js': ["src/backend/parse.js"]
      tests:
        files:
          'tests/test_bundle.js': ["tests/**/*Test.js"]
        options:
          external: ["src/**/index.js"]

    less:
      dev:
        files:
          "public/css/main.css": ["src/less/**/main.less"]
          "public/css/test.css": ["src/less/**/test.less"]
    karma:
      options:
        configFile: 'karma.coffee'

      run:
        options:
          singleRun: true

      runBackground:
        options:
          background: true


    watch:
      coffee:
        files: ["src/**/*.coffee", "public/**/*.html"]
        tasks: ["dev", "test"]
      styles:
        files: ["src/less/**/*.less"] 
        tasks: ["less"]
      tests:
        files: ["src/**/*.coffee", "public/**/*.html", "tests/**/*.coffee"]
        tasks: ["unit-tests"]
  }
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.registerTask 'test', ['coffee', 'browserify:test']
  grunt.registerTask 'dev', ['coffee:building','less', 'coffee', 'browserify']
  grunt.registerTask 'unit-tests', ['dev', 'coffee:tests', 'browserify:tests', 'karma:runBackground:run']
  grunt.registerTask 'unit-tests-run', ['dev', 'coffee:tests', 'browserify:tests', 'karma:run']
  grunt.registerTask 'default', ['dev']

