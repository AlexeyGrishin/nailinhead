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
    browserify:
      dev:
        files: 
          'public/js/index.js': ["public/js/angular.js", "src/**/*.js"]
    less:
      dev:
        files:
          "public/css/main.css": ["src/less/**/main.less"]
          "public/css/test.css": ["src/less/**/test.less"]
    watch:
      coffee:
        files: ["src/**/*.coffee", "public/**/*.html"]
        tasks: ["dev"]
      styles:
        files: ["src/less/**/*.less"] 
        tasks: ["less"]      
  }
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'dev', ['coffee:building','less', 'coffee', 'browserify']
  grunt.registerTask 'default', ['dev']

