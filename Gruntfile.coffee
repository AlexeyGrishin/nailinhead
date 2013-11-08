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
      test:
        files:
          "public/js/test.js": ["src/model/*.coffee"]
        options:
          bare: true
      tests:
        expand: true
        cwd: "tests"
        src: ["**/*.coffee"]
        dest: "tests"
        ext: ".js"
        options:
          bare: true
    browserify:
      dev:
        files: 
          'public/js/index.js': ["src/**/*.js"]
        options:
          require: true
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
        tasks: ["dev", "unit-tests"]
      styles:
        files: ["src/less/**/*.less"] 
        tasks: ["less"]
      tests:
        files: ["tests/**/*.coffee"]
        tasks: ["unit-tests"]
  }
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.registerTask 'dev', ['coffee:building','less', 'coffee', 'browserify']
  grunt.registerTask 'test', ['coffee:test']
  grunt.registerTask 'unit-tests', ['coffee:tests', 'karma:runBackground:run']
  grunt.registerTask 'unit-tests-run', ['dev', 'coffee:tests', 'karma:run']
  grunt.registerTask 'default', ['dev']

