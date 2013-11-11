module.exports = (config) ->
  config.set
    frameworks: ['jasmine']
    files: ["public/js/jquery.js",
            "public/js/angular.js",
            "public/js/bootstrap.js",
            "node_modules/underscore/underscore.js",
            "public/js/parse-1.2.12.js", "src/model/persistence.js", "src/model/tasks.js", "src/model/report.js",
            "public/js/granula.js",
            "public/js/index.js",
            "node_modules/ng-midway-tester/src/ngMidwayTester.js",
            "tests/lib/jasmine-jquery.js",
            "tests/model/parseUtil.js",
            "tests/model/*Spec.js",
            "tests/acceptance/utils.js",
            "tests/acceptance/*Spec.js"]
    browsers: ['Chrome']
    reporters: ['progress', 'html']
    proxies: {
      '/': 'http://puzzle.test/'
    }
