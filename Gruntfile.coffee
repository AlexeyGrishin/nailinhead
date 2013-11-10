module.exports = (grunt) ->
  version = require('./package.json').version
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
      release:
        files: ["package.json"]
        tasks: ["release"]
    uglify:
      release:
        files:
          "release/js/index.js": ["public/js/granula.js", "public/js/index.js"]
    cssmin:
      release:
        files:
          "release/css/main.css": ["public/css/main.css"]
    preprocess:
      release:
        expand: true
        cwd: 'public'
        src: "**/*.html"
        dest: "release/"
        options:
          context:
            version: version
    copy:
      fonts:
        expand: true
        cwd: "public/css"
        src: "OpenSans*"
        dest: "release/css/"
      images:
        expand: true
        cwd: "public/img/"
        src: "*"
        dest: "release/img/"
      someCss:
        files: {
          "release/css/bootstrap.min.css": ["public/css/bootstrap.min.css"]
        }
      someJs:
        files:
          "release/js/jquery-ui-1.10.3.custom.min.js": ["public/js/jquery-ui-1.10.3.custom.min.js"]
          "release/js/parse-1.2.12.min.js": ["public/js/parse-1.2.12.min.js"]
      lang:
        expand: true
        cwd: "public/lang/"
        src: "*.json"
        dest: "release/lang/"
    clean:
      release: ['release']

  }
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-preprocess'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.registerTask 'dev', ['coffee:building','less', 'coffee', 'browserify']
  grunt.registerTask 'unit-tests', ['coffee:tests', 'karma:runBackground:run']
  grunt.registerTask 'unit-tests-run', ['dev', 'coffee:tests', 'karma:run']
  grunt.registerTask 'release', ['dev', 'clean:release', 'uglify:release', 'preprocess:release', 'cssmin:release',
                                 'copy:lang', 'copy:images', 'copy:someJs', 'copy:someCss', 'copy:fonts']
  grunt.registerTask 'default', ['release']
