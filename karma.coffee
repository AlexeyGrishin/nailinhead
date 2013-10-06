module.exports = (config) ->
  config.set
    frameworks: ['jasmine']
    files: ["public/js/jquery.js", "public/js/bootstrap.js", "public/js/angular.js",
            "public/js/parse-1.2.12.js", "public/js/index.js", "tests/test_bundle.js"]
    browsers: ['Chrome']
    reporters: ['progress', 'html']