module.exports = (config) ->
  config.set
    frameworks: ['jasmine']
    files: ["public/js/jquery.js",
            "node_modules/underscore/underscore.js",
            "public/js/parse-1.2.12.js", "src/model/persistence.js", "src/model/tasks.js", "tests/**/*.js"]
    browsers: ['Chrome']
    reporters: ['progress', 'html']