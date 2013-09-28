module.exports = (grunt) ->
  grunt.initConfig {
    coffee:
      dev:
        expand: true
        cwd: "src"
        src: ["**/*.coffee"]
        dest: "src"
        ext: ".js"
    browserify:
      dev:
        files: 
          'public/js/index.js': ["src/**/*.js"]
    less:
      dev:
        files:
          "public/css/main.css": ["src/less/**/*.less"]
    watch:
      coffee:
        files: ["src/**/*.coffee"]
        tasks: ["dev"]
      styles:
        files: ["src/less/**/*.less"] 
        tasks: ["less"]      
  }
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'dev', ['less', 'coffee', 'browserify']
  grunt.registerTask 'default', ['dev']

