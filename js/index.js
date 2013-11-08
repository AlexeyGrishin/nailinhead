;(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function() {
  var __slice = [].slice;

  module.exports = function(app) {
    app.service('loading', function() {
      var newOp;
      newOp = function() {
        return {
          title: "Working with server",
          toString: function() {
            return this.title;
          }
        };
      };
      return {
        operations: [],
        count: 0,
        onStart: function(operation) {
          var _this = this;
          if (operation == null) {
            operation = newOp();
          }
          this.operations.push(operation);
          this.count++;
          return function() {
            _this.operations.splice(_this.operations.indexOf(operation), 1);
            return _this.count--;
          };
        },
        callback: function(realCb) {
          var onEnd;
          onEnd = this.onStart;
          return function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            onEnd();
            return realCb.apply(null, args);
          };
        }
      };
    });
    return app.directive('loading-indicator', function(loading) {
      return {
        template: "<b>{{loading.count}}</b>",
        link: function(scope, el, attrs) {
          return scope.loading = loading;
        }
      };
    });
  };

}).call(this);

},{}],2:[function(require,module,exports){
(function() {
  module.exports = function(app) {
    return app.service('auth', function(backend, $rootScope) {
      var auth, fireEvent, loggedIn, loginFailed;
      loggedIn = function() {
        console.log("auth:loggedIn");
        return $rootScope.$broadcast('auth:loggedIn');
      };
      loginFailed = function() {
        console.log("auth:loginFailed");
        return $rootScope.$broadcast('auth:loginFailed');
      };
      fireEvent = function(res, error) {
        if (error) {
          return loginFailed();
        } else {
          return loggedIn();
        }
      };
      auth = {
        loggedIn: false,
        currentUser: backend.currentUser,
        username: null,
        password: null,
        register: function(username, password, options, cb) {
          var _this = this;
          return backend.register(angular.extend({
            username: username,
            password: password
          }, options), function(res, error) {
            if (!error) {
              _this.loggedIn = true;
            }
            fireEvent(res, error);
            return cb(res, error);
          });
        },
        login: function(username, password, cb) {
          var _this = this;
          return backend.login({
            username: username,
            password: password
          }, function(res, error) {
            if (!error) {
              _this.loggedIn = true;
            }
            fireEvent(res, error);
            return cb(res, error);
          });
        },
        logout: function(cb) {
          var _this = this;
          return backend.logout(function() {
            _this.loggedIn = false;
            loginFailed();
            return cb();
          });
        },
        check: function() {
          var _this = this;
          $rootScope.$broadcast('auth:checking');
          return backend.getLoginStatus(function(loggedInFlag) {
            _this.loggedIn = loggedInFlag;
            return fireEvent(loggedInFlag, !loggedInFlag);
          });
        }
      };
      return auth;
    });
  };

}).call(this);

},{}],3:[function(require,module,exports){
(function() {
  var Backend, Group, Me, Project, Report;

  Project = Parse.Object.extend("Project");

  Group = Parse.Object.extend("Group");

  Report = Parse.Object.extend("Report");

  Me = function() {
    return Parse.User.current();
  };

  Backend = {
    currentUser: {},
    init: function() {
      return Parse.initialize('eXTzA1h8G4j7HzEpKbsHpJh4ZbzpkFKRzxn50gJp', 'vJpkQiAsEzDuoNGjRPUr0xcbgP2g7G4nnnQax7Mf');
    },
    getLoginStatus: function(cb) {
      var authenticated, _ref;
      authenticated = (_ref = Me()) != null ? _ref.authenticated() : void 0;
      if (!authenticated) {
        Parse.User.logOut();
        return cb(authenticated);
      } else {
        return this._updateCurrentUser(function() {
          return cb(authenticated);
        });
      }
    },
    _updateCurrentUser: function(cb) {
      var _this = this;
      if (cb == null) {
        cb = function() {};
      }
      if (Me() === null) {
        return cb();
      }
      return Me().fetch({
        success: function() {
          var _ref;
          angular.copy((_ref = Me()) != null ? _ref.toJSON() : void 0, _this.currentUser);
          return cb();
        }
      });
    },
    register: function(userData, cb) {
      var user,
        _this = this;
      user = new Parse.User(userData);
      return user.signUp(null, this.defaultHandler(function(user, error) {
        return _this._updateCurrentUser(function() {
          return cb(user, error);
        });
      }));
    },
    login: function(userData, cb) {
      var _this = this;
      return Parse.User.logIn(userData.username, userData.password, this.defaultHandler(function(res, error) {
        return _this._updateCurrentUser(function() {
          return cb(res, error);
        });
      }));
    },
    logout: function(cb) {
      Parse.User.logOut();
      angular.copy({}, this.currentUser);
      return cb();
    },
    loading: 0,
    defaultHandler: function(successCb) {
      var _this = this;
      if (successCb == null) {
        successCb = function() {};
      }
      this.loading++;
      return {
        success: function(data) {
          successCb(data);
          return _this.loading--;
        },
        error: function(_, error) {
          $(_this).trigger("backend.error", error);
          successCb(null, error);
          return _this.loading--;
        }
      };
    }
  };

  module.exports = Backend;

  window.Backend = Backend;

}).call(this);

},{}],4:[function(require,module,exports){
(function() {
  var Backend;

  Backend = require('./parse');

  module.exports = function(app) {
    return app.service('backend', function($rootScope) {
      Backend.init();
      $(Backend).on('backend.error', function(event, error) {
        console.error(error);
        return $rootScope.$broadcast('backend.error', error);
      });
      return Backend;
    });
  };

}).call(this);

},{"./parse":3}],5:[function(require,module,exports){
(function() {
  var SHOW_COMPLETED_KEY, app, getDialog, safeApply;

  app = angular.module('puzzle', ['granula']);

  (require('./backend/parse_angular'))(app);

  getDialog = (require('./ui'))(app).getDialog;

  (require('./async'))(app);

  (require('./tasks/selection'))(app);

  (require('./tasks/actions'))(app);

  (require('./auth/auth'))(app);

  (require('./model/tasks_angular'))(app);

  app.config(function(budgetProvider) {});

  app.controller('global', function($scope, budget, backend, auth, $location, $route) {
    var reset;
    $scope.loading = true;
    reset = function() {
      $scope.budget = {
        amount: 0
      };
      return $scope.booking = {
        amount: function() {
          return void 0;
        }
      };
    };
    reset();
    $scope.auth = auth;
    $scope.$on('auth:loggedIn', function() {
      console.log("load tasks");
      return budget.load().then((function(budget) {
        $scope.budget = budget;
        $scope.booking = budget.booked;
        $scope.loading = false;
        return $scope.$apply();
      }), function(error) {
        if (error) {
          return console.error(error);
        }
      });
    });
    $scope.$on('auth:loginFailed', function() {
      return $location.path("/auth");
    });
    $scope.logout = function() {
      reset();
      budget.unload();
      return auth.logout(function() {});
    };
    auth.check();
    $scope.$on('$routeChangeSuccess', function(ev, route) {
      return $scope.section = route.section;
    });
    return $scope["import"] = function() {
      var b, continueWithTasks, pByName, pData, project, projectsToSave, _i, _len, _ref;
      b = $scope.budget;
      b.set(data.amount);
      pByName = {};
      projectsToSave = data.projects.length;
      _ref = data.projects;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pData = _ref[_i];
        project = b.addProject(pData, function() {
          projectsToSave--;
          if (projectsToSave === 0) {
            return continueWithTasks();
          }
        });
        pByName[project.name] = project;
      }
      return continueWithTasks = function() {
        var tData, task, _j, _len1, _ref1, _results;
        _ref1 = data.tasks;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          tData = _ref1[_j];
          project = pByName[tData.project];
          if (project === void 0) {
            console.error("Cannot import task - unknown project '" + tData.project + "' - " + (JSON.stringify(tData, null, 4)));
            continue;
          }
          _results.push(task = project.addTask(tData));
        }
        return _results;
      };
    };
  });

  app.controller('header', function($scope) {
    return $scope.$watch('budget.amount', function(newVal) {
      if (!$scope.auth.loggedIn) {
        return;
      }
      return $scope.budget.set(newVal);
    });
  });

  app.config(function($routeProvider) {
    $routeProvider.when('/', {
      controller: 'projects',
      templateUrl: './projects.html',
      section: 'projects'
    });
    $routeProvider.when('/reports/:year/:month', {
      controller: 'reports',
      templateUrl: './reports.html',
      section: 'reports'
    });
    $routeProvider.when('/reports/:year', {
      controller: 'reports',
      templateUrl: './reports.html',
      section: 'reports'
    });
    $routeProvider.when('/reports', {
      controller: 'reports',
      templateUrl: './reports.html',
      section: 'reports'
    });
    $routeProvider.when('/auth', {
      controller: 'login',
      templateUrl: './login.html'
    });
    return $routeProvider.when('/:project', {
      controller: 'project',
      templateUrl: './project.html',
      section: 'projects'
    });
  });

  app.controller('login', function($scope, auth, $location) {
    var onLogReg, startCall;
    $scope.auth = auth;
    onLogReg = function(user, error) {
      if (user) {
        $location.path("/");
      } else {
        $scope.error = error;
        error.isLogin = true;
      }
      $scope.logReg = false;
      return $scope.$apply();
    };
    startCall = function() {
      $scope.error = null;
      return $scope.logReg = true;
    };
    $scope.register = function() {
      startCall();
      return auth.register($scope.auth.username, $scope.auth.password, {}, onLogReg);
    };
    return $scope.login = function() {
      startCall();
      return auth.login($scope.auth.username, $scope.auth.password, onLogReg);
    };
  });

  app.controller('projects', function($scope, $location, tasksSelection) {
    $scope.newProject = {
      title: ""
    };
    $scope.addProject = function() {
      if ($scope.newProject.title) {
        $scope.budget.addProject({
          name: $scope.newProject.title
        }, function(err, proj) {
          return $scope.$apply(function() {
            return $location.path("/" + proj.objectId);
          });
        });
      }
      return $scope.$apply();
    };
    $scope.deleteProject = function(project) {
      return project["delete"]();
    };
    $scope.isBooked = function(task) {
      return $scope.booking.include(task);
    };
    $scope.selection = tasksSelection.createSelection();
    return $scope.$on("$destroy", function() {
      return $scope.selection.deselectAll();
    });
  });

  SHOW_COMPLETED_KEY = 'NIH_proj_show_completed';

  safeApply = function($scope) {
    if (!$scope.$$phase) {
      return $scope.$apply();
    }
  };

  app.controller('project', function(tasksSelection, budget, $scope, $routeParams) {
    var projectId, safeAmount;
    $scope.showCompleted = (typeof localStorage !== "undefined" && localStorage !== null ? localStorage[SHOW_COMPLETED_KEY] : void 0) === 'true';
    $scope.$watch('showCompleted', function() {
      return typeof localStorage !== "undefined" && localStorage !== null ? localStorage[SHOW_COMPLETED_KEY] = $scope.showCompleted : void 0;
    });
    projectId = $routeParams.project;
    budget.whenLoad().then(function(budget) {
      var visibleTasks;
      $scope.project = budget.getProject(projectId);
      visibleTasks = $scope.showCompleted ? $scope.project.tasks : $scope.project.nonCompleted();
      if (visibleTasks.length === 0) {
        $scope.addTaskDialog = true;
      }
      return safeApply($scope);
    });
    safeAmount = function(amount) {
      amount = parseInt(amount);
      if (isNaN(amount) || amount < 1) {
        amount = 1;
      }
      return amount;
    };
    $scope.currentTask = {};
    $scope.newTask = {
      title: "",
      cost1: 0,
      amount: 1
    };
    $scope.addTask = function() {
      $scope.newTask.amount = safeAmount($scope.newTask.amount);
      $scope.newTask.cost = $scope.newTask.cost1 * $scope.newTask.amount;
      if ($scope.newTask.title) {
        $scope.project.addTask($scope.newTask, function() {
          return safeApply($scope);
        });
      }
      return setTimeout((function() {
        $scope.addTaskDialog = true;
        return $scope.$apply();
      }), 0);
    };
    $scope.deleteTask = function(task) {
      return $scope.project.deleteTask(task);
    };
    $scope.toggleTask = function(task) {
      return task.toggle().then(function() {
        return safeApply($scope);
      });
    };
    $scope.isBooked = function(task) {
      return $scope.booking.include(task);
    };
    $scope.toggleBookingTask = function(task) {
      return $scope.booking.toggle(task);
    };
    $scope.taskInEdit = null;
    $scope.editTask = function(task) {
      var wasEdited;
      wasEdited = $scope.isInEdit(task);
      $scope.cancelEdit();
      if (wasEdited) {
        return;
      }
      $scope.selection.deselectAll();
      $scope.taskInEdit = {
        original: task,
        edited: $.extend({}, task)
      };
      return $scope.taskInEdit.edited.cost1 = $scope.taskInEdit.edited.cost / $scope.taskInEdit.edited.amount;
    };
    $scope.cancelEdit = function() {
      return $scope.taskInEdit = null;
    };
    $scope.saveTask = function(task) {
      task.withStatusUpdate(function(task) {
        task.title = $scope.taskInEdit.edited.title;
        task.amount = safeAmount($scope.taskInEdit.edited.amount);
        return task.cost = $scope.taskInEdit.edited.cost1 * task.amount;
      });
      task.save();
      return $scope.cancelEdit();
    };
    $scope.isInEdit = function(task) {
      var _ref;
      return ((_ref = $scope.taskInEdit) != null ? _ref.original : void 0) === task;
    };
    $scope.selection = tasksSelection.createSelection();
    return $scope.$on("$destroy", function() {
      return $scope.selection.deselectAll();
    });
  });

  app.controller('reports', function(budget, $scope, $routeParams, $location) {
    var date, month, today, year;
    year = parseFloat($routeParams.year);
    month = parseFloat($routeParams.month);
    if (!isNaN(year) && isNaN(month)) {
      month = 0;
    }
    today = new Date();
    if (isNaN(year) && isNaN(month)) {
      date = today;
      year = date.getFullYear();
      month = date.getMonth();
    } else if (year > today.getFullYear() || month > today.getMonth()) {
      $location.path("/reports");
    } else {
      date = new Date();
      date.setFullYear(year);
      date.setMonth(month);
    }
    $scope.loading = true;
    $scope.month = month;
    $scope.monthR = month + 1;
    $scope.year = year;
    $scope.prev = {
      month: month === 0 ? 11 : month - 1,
      year: month === 0 ? year - 1 : year
    };
    $scope.next = {
      month: month === 11 ? 0 : month + 1,
      year: month === 11 ? year + 1 : year
    };
    $scope.hasNext = true;
    $scope.report = {
      loading: true
    };
    return budget.whenLoad().then(function(budget) {
      $scope.report = budget.report($scope.month, $scope.year);
      $scope.hasNext = year < today.getFullYear() || month < today.getMonth();
      return safeApply($scope);
    });
  });

  app.filter('nonCompleted', function() {
    return function(input, doFilter) {
      if (!doFilter || input === void 0) {
        return input;
      }
      return input.filter(function(t) {
        return !t.is('completed');
      });
    };
  });

  app.service('projectThumbModel', function() {
    return {
      create: function(project, maxAmountOfTasks) {
        var calculateProgress, calculateTasksToShow, getTotal;
        getTotal = function(project) {
          return project.tasks.length;
        };
        calculateProgress = function(project) {
          var count, status, title, total, _ref, _results;
          total = getTotal(project);
          _ref = {
            completed: "tasks completed",
            available: "tasks ready to be completed",
            unavailable: "tasks cannot be completed right now"
          };
          _results = [];
          for (status in _ref) {
            title = _ref[status];
            count = project[status]().length;
            _results.push({
              percent: count / total * 100,
              amount: count,
              total: total,
              name: status,
              title: "of " + total + " " + title
            });
          }
          return _results;
        };
        calculateTasksToShow = function(project) {
          var availableTasks, completedTasks, rest, tasksToShow, total, unavailableTasks;
          availableTasks = project.available();
          unavailableTasks = project.unavailable();
          completedTasks = project.completed();
          total = availableTasks.length + unavailableTasks.length + completedTasks.length;
          tasksToShow = availableTasks.slice().concat(unavailableTasks).slice(0, maxAmountOfTasks);
          if (tasksToShow.length < availableTasks.length + unavailableTasks.length) {
            tasksToShow.pop();
            rest = total - maxAmountOfTasks + 1;
            tasksToShow.push({
              rest: rest,
              status: "more",
              text: "..."
            });
          }
          return tasksToShow;
        };
        return {
          update: function() {
            var index, prog, _i, _len, _ref, _results;
            _ref = calculateProgress(project);
            _results = [];
            for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
              prog = _ref[index];
              _results.push(this.progressToShow[index] = prog);
            }
            return _results;
          },
          tasksToShow: calculateTasksToShow(project),
          progressToShow: calculateProgress(project)
        };
      }
    };
  });

  app.directive('projectThumb', function(projectThumbModel, $location) {
    return {
      scope: {
        project: "=projectThumb",
        selection: "=selection",
        deleteProject: "&deleteProject",
        isBooked: "&isBooked"
      },
      replace: true,
      templateUrl: "partial/project-thumb.html",
      link: function(scope, el, attrs) {
        var _ref;
        scope.thumb = projectThumbModel.create(scope.project, (_ref = attrs.thumbs) != null ? _ref : 9, scope.thumb);
        scope.click = function(task) {
          if (task.status === "more") {
            return $location.path("/" + scope.project.objectId);
          }
        };
        return scope.isSelected = function(task) {
          return scope.selection.isSelected(task);
        };
      }
    };
  });

  app.directive('ngEnter', function() {
    return function(scope, el, attrs) {
      return el.keydown(function(e) {
        if (e.which === 13) {
          return scope.$apply(function() {
            return scope.$eval(attrs.ngEnter);
          });
        }
      });
    };
  });

}).call(this);

},{"./async":1,"./auth/auth":2,"./backend/parse_angular":4,"./model/tasks_angular":8,"./tasks/actions":9,"./tasks/selection":10,"./ui":11}],6:[function(require,module,exports){
(function() {
  var BgSaver, MemClassMethods, MemInstanceMethods, ModelMixin, ParseClassMethods, ParseInstanceMethods, ParseNowriteInstanceMethods, ParseUtils, createMixin, parseBgSaver, parseSaver, parseSetAll,
    __slice = [].slice;

  ParseUtils = {
    setSafe: function(obj, attr, val, okCb, errCb) {
      var curVal, delta, promise;
      curVal = obj.get(attr);
      if (typeof val === 'number') {
        delta = val - (curVal != null ? curVal : 0);
        obj.increment(attr, delta);
      } else {
        obj.set(attr, val);
      }
      promise = new Parse.Promise();
      promise._thenRunCallbacks({
        success: okCb,
        error: errCb
      });
      obj.save(null, {
        success: function(result) {
          if (result.get(attr) === val) {
            return promise.resolve(result);
          } else {
            if (delta !== void 0) {
              obj.increment(attr, -delta);
              obj.save();
            }
            return promise.reject({
              conflict: true
            });
          }
        },
        error: function(_, error) {
          return promise.reject(error);
        }
      });
      return promise;
    },
    structToQuery: function(parseClassName, data) {
      var name, q, val;
      q = new Parse.Query(parseClassName);
      for (name in data) {
        val = data[name];
        if (val === '@currentUser') {
          q.equalTo(name, Parse.User.current());
        } else {
          q.equalTo(name, val);
        }
      }
      return q;
    },
    afterFind: function(items, options, promise) {
      var countdown, loading, res, _ref, _ref1;
      options.processItem = (_ref = options.processItem) != null ? _ref : function(item) {
        return item;
      };
      options.postProcessItem = (_ref1 = options.postProcessItem) != null ? _ref1 : function(item, cb) {
        return cb(item);
      };
      loading = items.length;
      res = [];
      if (loading === 0) {
        return promise.resolve(res);
      }
      countdown = function() {
        loading--;
        if (loading === 0) {
          return promise.resolve(res);
        }
      };
      res = items.map(options.processItem);
      return res.forEach(function(o) {
        return options.postProcessItem(o, countdown);
      });
    },
    find: function(parseClassName, data, options) {
      var promise, q,
        _this = this;
      q = this.structToQuery(parseClassName, data);
      promise = new Parse.Promise();
      promise._thenRunCallbacks(options);
      q.find().then((function(items) {
        return _this.afterFind(items, options, promise);
      }), function(error) {
        return promise.reject(error);
      });
      return promise;
    }
  };

  BgSaver = (function() {
    function BgSaver(options) {
      var _ref, _ref1;
      if (options == null) {
        options = {};
      }
      this.delay = (_ref = options.delay) != null ? _ref : 1000;
      this.idGetter = (_ref1 = options.idGetter) != null ? _ref1 : function(obj) {
        return obj.id;
      };
      this.saver = options.saver;
      this.queue = [];
      this.to = null;
    }

    BgSaver.prototype.save = function(obj) {
      var existentInMap, promise,
        _this = this;
      existentInMap = this.queue.filter(function(q) {
        return _this.idGetter(q.obj) === _this.idGetter(obj);
      })[0];
      if (existentInMap) {
        console.log("Object already in queue - " + (this.idGetter(obj)) + " == " + (this.idGetter(existentInMap.obj)));
        return existentInMap.promise;
      }
      console.log("Push object to saving queue - " + (this.idGetter(obj)));
      promise = new Parse.Promise();
      this.queue.push({
        obj: obj,
        promise: promise
      });
      clearInterval(this.to);
      this.to = setTimeout(this._save.bind(this), this.delay);
      return promise;
    };

    BgSaver.prototype._save = function() {
      var o, _i, _len, _ref, _results,
        _this = this;
      console.log("Time to save queue - " + this.queue.length + " objects");
      _ref = this.queue.splice(0, this.queue.length);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        o = _ref[_i];
        _results.push((function(_arg) {
          var obj, promise;
          obj = _arg.obj, promise = _arg.promise;
          return _this._saveObject(obj).then((function(res) {
            return promise.resolve(res);
          }), function(err) {
            return promise.reject(err);
          });
        })(o));
      }
      return _results;
    };

    BgSaver.prototype._saveObject = function(obj, options) {
      return this.saver.save(obj, options);
    };

    BgSaver.prototype.flush = function() {
      console.log("Flush objects");
      return this._save();
    };

    BgSaver.prototype.saveNow = function(obj, options) {
      console.log("Save immediately - " + obj.constructor.name);
      clearTimeout(this.to);
      this._save();
      return this._saveObject(obj, options);
    };

    return BgSaver;

  })();

  parseSaver = function() {
    return {
      save: function(obj, options) {
        return obj.save(null, options);
      },
      saveNow: function(obj, options) {
        return obj.save(null, options);
      },
      flush: function() {}
    };
  };

  parseBgSaver = function(options) {
    var bgSaver;
    if (options == null) {
      options = {};
    }
    options.saver = parseSaver();
    bgSaver = new BgSaver(options);
    return {
      save: function(obj, options) {
        return bgSaver.save(obj, options);
      },
      saveNow: function(obj, options) {
        return bgSaver.saveNow(obj, options);
      },
      flush: function() {
        return bgSaver.flush();
      }
    };
  };

  ModelMixin = (function() {
    function ModelMixin() {}

    ModelMixin.properties = function() {
      var properties;
      properties = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (properties.length > 0) {
        return this.prototype.getPropertyNames = function() {
          return properties;
        };
      }
    };

    ModelMixin.prototype.save = function(data, options) {
      var promise,
        _this = this;
      if (options === void 0) {
        if (data != null ? data.success : void 0) {
          options = data;
          data = {};
        } else {
          options = {};
        }
      }
      options.data = data;
      if (!this.objectId) {
        options.now = true;
      }
      this.beforeSave();
      promise = new Parse.Promise();
      promise._thenRunCallbacks(options);
      delete options.success;
      delete options.error;
      this.persistence().save(this, options).then((function(json) {
        _this.load(json);
        return promise.resolve(_this);
      }), function(error) {
        return promise.reject(error);
      });
      return promise;
    };

    ModelMixin.prototype.load = function(data) {
      var name, val, _results;
      if (data == null) {
        data = {};
      }
      _results = [];
      for (name in data) {
        val = data[name];
        if (this[name] === '@currentUser') {
          continue;
        }
        if (typeof this[name] === 'object' && typeof val === 'string') {
          if (this[name].objectId === val) {
            continue;
          }
        }
        if (this[name] !== void 0 && val === void 0) {
          console.error("Local value is defined, but value from server is undefined: obj == " + this.constructor.name + "[" + this.objectId + "], prop == " + name + ", oldVal = " + this[name]);
          val = this[name];
        }
        _results.push(this[name] = val);
      }
      return _results;
    };

    ModelMixin.prototype.afterLoad = function(cb) {
      return cb();
    };

    ModelMixin.prototype.beforeSave = function() {};

    ModelMixin.prototype.getPropertyNames = function() {
      return Object.keys(this).filter(function(k) {
        return typeof this[k] !== 'function' && k.charAt(0) !== '_' && k.charAt(0) !== '$' && k !== 'persistence';
      });
    };

    return ModelMixin;

  })();

  ParseClassMethods = function(options) {
    if (options == null) {
      options = {
        linkToCurrentUser: true
      };
    }
    return function(clsName, cls, addInstanceMethods) {
      var ParseClass, parseClassName, _ref;
      parseClassName = (_ref = cls.PARSE_CLASS) != null ? _ref : clsName;
      ParseClass = Parse.Object.extend(parseClassName);
      return {
        find: function(data, options) {
          if (data == null) {
            data = {};
          }
          if (options == null) {
            options = {};
          }
          return ParseUtils.find(parseClassName, data, {
            success: options.success,
            error: options.error,
            processItem: function(item) {
              var o;
              o = new cls();
              addInstanceMethods(o, item);
              o.load(item.toJSON());
              return o;
            },
            postProcessItem: function(item, cb) {
              return item.afterLoad(cb);
            }
          });
        },
        init: function(obj) {
          var parseObj;
          parseObj = new ParseClass();
          parseObj.setACL(new Parse.ACL(Parse.User.current()));
          return addInstanceMethods(obj, parseObj);
        }
      };
    };
  };

  parseSetAll = function(parseObj, o, data) {
    var key, prop, val, _i, _len, _ref, _ref1, _results;
    if (data) {
      for (key in data) {
        val = data[key];
        o[key] = val;
      }
    }
    _ref = o.getPropertyNames().concat(["objectId"]);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      prop = _ref[_i];
      if (typeof o[prop] === 'number') {
        _results.push(parseObj.increment(prop, o[prop] - ((_ref1 = parseObj.get(prop)) != null ? _ref1 : 0)));
      } else if (o[prop] === '@currentUser') {
        _results.push(parseObj.set(prop, Parse.User.current()));
      } else if (o[prop] instanceof ModelMixin) {
        if (!o[prop].objectId) {
          throw new Error("Refered object " + prop + " shall be saved first");
        }
        _results.push(parseObj.set(prop, o[prop].objectId));
      } else {
        _results.push(parseObj.set(prop, o[prop]));
      }
    }
    return _results;
  };

  ParseInstanceMethods = function(saver) {
    if (saver == null) {
      saver = parseSaver();
    }
    return function(parseObj) {
      return {
        save: function(o, options) {
          var key, p, p2, saverMethod;
          saverMethod = options.now ? 'saveNow' : 'save';
          if (options.safe) {
            key = Object.keys(options.data)[0];
            o[key] = options.data[key];
            saver.flush();
            p = ParseUtils.setSafe(parseObj, key, options.data[key], options.success, options.error);
          } else {
            parseSetAll(parseObj, o, options.data);
            p = saver[saverMethod](parseObj, options);
          }
          p2 = new Parse.Promise();
          p.then((function(res) {
            return p2.resolve(res.toJSON());
          }), function(error) {
            return p2.reject(error);
          });
          return p2;
        }
      };
    };
  };

  ParseNowriteInstanceMethods = function() {
    return function(parseObj) {
      var id;
      id = 1;
      return {
        save: function(o, options) {
          var p;
          if (!o.objectId) {
            o.objectId = "" + o.constructor.name + "-" + (id++);
          }
          parseSetAll(parseObj, o, options.data);
          console.log("Save " + o.constructor.name + " / " + o.objectId + " = " + (JSON.stringify(parseObj.attributes)));
          p = new Parse.Promise();
          p._thenRunCallbacks(options);
          p.resolve(o);
          return p;
        }
      };
    };
  };

  MemClassMethods = function() {
    return function(clsName, cls, addInstanceMethods) {
      var memStorage, _memStorage;
      _memStorage = {};
      memStorage = function(clsName) {
        if (_memStorage[clsName] == null) {
          _memStorage[clsName] = [];
        }
        return _memStorage[clsName];
      };
      return {
        find: function(data, options) {
          var p;
          p = new Parse.Promise();
          p._thenRunCallbacks(options);
          p.resolve(memStorage(clsName).filter(function(obj) {
            var name, val;
            for (name in data) {
              val = data[name];
              if (obj[name] !== val && val !== "@currentUser") {
                return false;
              }
            }
            return true;
          }));
          return p;
        },
        init: function(o) {
          return addInstanceMethods(o, clsName, memStorage);
        }
      };
    };
  };

  MemInstanceMethods = function() {
    return function(clsName, memStorage) {
      return {
        save: function(o, options) {
          var n, p, v, _ref, _ref1;
          _ref1 = (_ref = options.data) != null ? _ref : {};
          for (n in _ref1) {
            v = _ref1[n];
            o[n] = v;
          }
          if (!o.objectId) {
            o.objectId = clsName + new Date().getTime();
            memStorage(clsName).push(o);
          }
          p = new Parse.Promise();
          p._thenRunCallbacks(options);
          p.resolve(o);
          return p;
        }
      };
    };
  };

  createMixin = function(mixinName, classMethods, instanceMethods) {
    var doMixin;
    doMixin = function(clsName, cls) {
      var addInstanceMethods, classes, method, mname, _ref, _results;
      if (typeof clsName === 'object') {
        classes = clsName;
        for (clsName in classes) {
          cls = classes[clsName];
          doMixin(clsName, cls);
        }
        return;
      }
      addInstanceMethods = function() {
        var args, mixin, obj;
        obj = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        mixin = instanceMethods.apply(null, args);
        return obj[mixinName] = function() {
          return mixin;
        };
      };
      _ref = classMethods(clsName, cls, addInstanceMethods);
      _results = [];
      for (mname in _ref) {
        method = _ref[mname];
        _results.push(cls[mname] = method);
      }
      return _results;
    };
    return doMixin;
  };

  ModelMixin.parseMixin = createMixin("persistence", ParseClassMethods(), ParseInstanceMethods());

  ModelMixin.parseBgMixin = createMixin("persistence", ParseClassMethods(), ParseInstanceMethods(parseBgSaver({
    delay: 2000
  })));

  ModelMixin.parseReadonlyMixin = createMixin("persistence", ParseClassMethods(), ParseNowriteInstanceMethods());

  ModelMixin.memMixin = createMixin("persistence", MemClassMethods(), MemInstanceMethods());

  this.require = false;

  if (require) {
    module.exports = ModelMixin;
  } else {
    window.ModelMixin = ModelMixin;
  }

}).call(this);

},{}],7:[function(require,module,exports){
(function() {
  var BOOKED, Budget, Group, ModelMixin, Project, Task, copy,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.require = false;

  if (require) {
    ModelMixin = require('./persistence');
  } else {
    ModelMixin = window.ModelMixin;
  }

  copy = function(props) {
    var key, o, val;
    o = {};
    for (key in props) {
      if (!__hasProp.call(props, key)) continue;
      val = props[key];
      o[key] = val;
    }
    return o;
  };

  Group = (function() {
    function Group(name, budget) {
      this.name = name;
      this.budget = budget;
    }

    Group.prototype.include = function(task) {
      return (task.groups != null) && task.groups.indexOf(this.name) > -1;
    };

    Group.prototype.tasks = function() {
      var _this = this;
      return this.budget.tasks.filter(function(t) {
        return t.completed === 0 && t.deleted === 0 && _this.include(t);
      });
    };

    Group.prototype.amount = function() {
      return this.tasks(this.budget).map(function(t) {
        return t.cost;
      }).reduce((function(a, b) {
        return a + b;
      }), 0);
    };

    Group.prototype.toggle = function(task) {
      if (this.include(task)) {
        task.groups.splice(task.groups.indexOf(this.name), 1);
      } else {
        task.groups.push(this.name);
      }
      return task.save();
    };

    return Group;

  })();

  Task = (function(_super) {
    __extends(Task, _super);

    Task.properties("title", "completed", "deleted", "cMonth", "cYear", "cProjectName", "project", "cost", "budget", "groups", "amount");

    function Task(data) {
      if (data == null) {
        data = {};
      }
      Task.init(this);
      this.load(data);
      this.deleted = 0;
      this.completed = 0;
      this.afterLoad();
    }

    Task.prototype._checkCost = function() {
      this.cost = parseInt(this.cost);
      if (isNaN(this.cost)) {
        this.cost = 0;
      }
      this.amount = parseInt(this.amount);
      if (isNaN(this.amount) || this.amount < 1) {
        return this.amount = 1;
      }
    };

    Task.prototype.afterLoad = function(cb) {
      if (cb == null) {
        cb = function() {};
      }
      this._checkCost();
      if (this.amount == null) {
        this.amount = 1;
      }
      if (this.groups == null) {
        this.groups = [];
      }
      this.updateStatus();
      return cb();
    };

    Task.prototype.withBudget = function(cb) {
      if (typeof this.budget === 'object') {
        return cb(this.budget);
      }
    };

    Task.prototype.withStatusUpdate = function(cb) {
      cb(this);
      return this.updateStatus();
    };

    Task.prototype.updateStatus = function() {
      var _this = this;
      this._checkCost();
      if (this.completed === 1) {
        return this.status = 'completed';
      } else {
        return this.withBudget(function(b) {
          return _this.status = b.getStatusForCost(_this.cost);
        });
      }
    };

    Task.prototype.toggle = function() {
      if (this.completed === 1) {
        return this.uncomplete();
      } else {
        return this.complete();
      }
    };

    Task.prototype.is = function(status) {
      return status === this.status;
    };

    Task.prototype.complete = function() {
      var p,
        _this = this;
      if (this.completed === 1) {
        return;
      }
      p = new Parse.Promise();
      this.withBudget(function(b) {
        return b.onComplete(_this);
      });
      this.save({
        completed: 1
      }, {
        safe: true,
        success: function() {
          var comDate;
          comDate = new Date();
          return _this.save({
            cMonth: comDate.getMonth(),
            cYear: comDate.getFullYear(),
            cProjectName: _this.project.name
          });
        },
        error: function(err) {
          if (err.conflict) {
            return _this.withBudget(function(b) {
              return b.onUncomplete(_this);
            });
          }
        }
      });
      this.updateStatus();
      return p;
    };

    Task.prototype.uncomplete = function() {
      var p,
        _this = this;
      if (this.completed === 0) {
        return;
      }
      this.withBudget(function(b) {
        return b.onUncomplete(_this);
      });
      p = this.save({
        completed: 0
      }, {
        safe: true,
        success: function() {},
        error: function(err) {
          return _this.withBudget(function(b) {
            if (err.conflict) {
              return b.onComplete(_this);
            }
          });
        }
      });
      this.updateStatus();
      return p;
    };

    Task.prototype["delete"] = function() {
      return this.save({
        deleted: 1
      }, {
        safe: true
      });
    };

    return Task;

  })(ModelMixin);

  BOOKED = "booked";

  Budget = (function(_super) {
    __extends(Budget, _super);

    Budget.properties("amount", "owner", "currency");

    function Budget(_arg) {
      this.amount = (_arg != null ? _arg : {}).amount;
      Budget.init(this);
      this.tasks = [];
      this.booked = new Group(BOOKED, this);
      this.owner = "@currentUser";
    }

    Budget.prototype.linkRelation = function(fieldName) {
      var _this = this;
      return function(obj) {
        return obj[fieldName] = function(act) {
          return act(_this);
        };
      };
    };

    Budget.prototype.afterLoad = function(cb) {
      var _this = this;
      if (this.currency == null) {
        this.currency = 'RUR';
      }
      return Task.find({
        budget: this.objectId,
        deleted: 0
      }, {
        success: function(tasks) {
          tasks.forEach(function(t) {
            t.budget = _this;
            return t.updateStatus();
          });
          return _this.tasks = tasks;
        },
        error: function() {}
      }).then(function() {
        return Project.find({
          budget: _this.objectId,
          deleted: 0
        }, {
          success: function(projects) {
            projects.forEach(function(p) {
              return p.budget = _this;
            });
            _this.projects = projects;
            _this._linkProjectsTasks();
            return cb();
          }
        });
      });
    };

    Budget.prototype._linkProjectsTasks = function() {
      var pid,
        _this = this;
      pid = {};
      this.projects.forEach(function(p) {
        return pid[p.objectId] = p;
      });
      return this.tasks = this.tasks.filter(function(t) {
        var project;
        if (!t.project) {
          console.error("Task does not have link to project, so it will be ignored");
          return false;
        }
        if (!pid[t.project]) {
          console.error("Project with id = " + t.project + " does not belong to this budget");
          return false;
        }
        project = pid[t.project];
        t.project = project;
        project.attachTask(t);
        return true;
      });
    };

    Budget.prototype.isEnough = function(task) {
      return task.cost <= this.amount;
    };

    Budget.prototype.getStatusForCost = function(cost) {
      if (this.isEnough({
        cost: cost
      })) {
        return 'available';
      } else {
        return 'unavailable';
      }
    };

    Budget.prototype.report = function(month, year) {
      var report;
      report = {
        loading: true,
        tasks: []
      };
      Task.find({
        budget: this.objectId,
        completed: 1,
        cMonth: month,
        cYear: year
      }, {
        success: function(tasks) {
          report.loading = false;
          return report.tasks = tasks;
        },
        error: function() {}
      });
      return report;
    };

    Budget.prototype.set = function(amount, force) {
      var newAmount;
      if (force == null) {
        force = false;
      }
      newAmount = parseInt(amount);
      if (this.amount === void 0) {
        this.amount = amount;
      }
      if (this.amount === newAmount) {
        return;
      }
      this.save({
        amount: newAmount
      }, {
        now: force
      });
      return this.updateStatuses();
    };

    Budget.prototype.onComplete = function(task) {
      return this.set(this.amount - task.cost);
    };

    Budget.prototype.onUncomplete = function(task) {
      return this.set(this.amount + task.cost);
    };

    Budget.prototype.updateStatuses = function(container) {
      var _this = this;
      if (container == null) {
        container = this;
      }
      return container.tasks.forEach(function(t) {
        return t.updateStatus();
      });
    };

    Budget.prototype.addProject = function(props, cb) {
      var project,
        _this = this;
      if (cb == null) {
        cb = function() {};
      }
      props = copy(props);
      props.budget = this;
      project = new Project(props);
      project.save().then((function(project) {
        project.budget = _this;
        _this.projects.push(project);
        return cb(null, project);
      }), function(err) {
        return cb(err);
      });
      return project;
    };

    Budget.prototype.getProject = function(id) {
      var _ref;
      return (_ref = this.projects.filter(function(p) {
        return p.objectId === id;
      })[0]) != null ? _ref : null;
    };

    Budget.prototype.deleteProject = function(proj) {
      return this.projects.splice(this.projects.indexOf(proj), 1);
    };

    Budget.prototype.addTask = function(props, cb) {
      var task,
        _this = this;
      if (cb == null) {
        cb = function() {};
      }
      props = copy(props);
      props.budget = this;
      task = new Task(props);
      this.tasks.push(task);
      task.project.tasks.push(task);
      task.save().then((function(task) {
        _this.linkRelation("withBudget")(task);
        _this.updateStatuses(props.updateStatusesFor);
        return cb(null, task);
      }), function(err) {
        return cb(err);
      });
      return task;
    };

    Budget.load = function(cb) {
      return Budget.find({
        owner: "@currentUser"
      }, {
        success: function(budgets) {
          if (budgets.length > 0) {
            return cb(null, budgets[0]);
          } else {
            return new Budget({
              amount: 0
            }).save().then((function(b) {
              return cb(null, b);
            }), function(err) {
              return cb(err);
            });
          }
        },
        error: function(_, e) {
          return cb(e);
        }
      });
    };

    return Budget;

  })(ModelMixin);

  Project = (function(_super) {
    __extends(Project, _super);

    Project.PARSE_CLASS = "Project2";

    Project.properties("name", "deleted", "budget");

    function Project(_arg) {
      var _ref;
      _ref = _arg != null ? _arg : {}, this.name = _ref.name, this.budget = _ref.budget;
      Project.init(this);
      this.deleted = 0;
      this.tasks = [];
    }

    Project.prototype.attachTask = function(task) {
      return this.tasks.push(task);
    };

    Project.prototype.nonDeleted = function() {
      return this.tasks.filter(function(t) {
        return !t.deleted;
      });
    };

    Project.prototype.completed = function() {
      return this.tasks.filter(function(t) {
        return t.status === 'completed';
      });
    };

    Project.prototype.nonCompleted = function() {
      return this.tasks.filter(function(t) {
        return t.status !== 'completed';
      });
    };

    Project.prototype.available = function() {
      return this.tasks.filter(function(t) {
        return t.status === 'available';
      });
    };

    Project.prototype.unavailable = function() {
      return this.tasks.filter(function(t) {
        return t.status === 'unavailable';
      });
    };

    Project.prototype.addTask = function(props, cb) {
      props = copy(props);
      props.project = this;
      return this.budget.addTask(props, cb);
    };

    Project.prototype.deleteTask = function(task) {
      var p;
      p = task["delete"]();
      this.tasks.splice(this.tasks.indexOf(task), 1);
      return p;
    };

    Project.prototype["delete"] = function() {
      var p;
      p = this.save({
        deleted: 1
      }, {
        safe: true
      });
      this.budget.deleteProject(this);
      return p;
    };

    return Project;

  })(ModelMixin);

  ModelMixin.parseMixin({
    Task: Task,
    Budget: Budget,
    Project: Project
  });

  if (require) {
    module.exports = {
      Budget: Budget,
      remix: function(mixin) {
        return mixin({
          Task: Task,
          Budget: Budget,
          Project: Project
        });
      }
    };
  } else {
    window.Budget = Budget;
    window.Task = Task;
    window.Project = Project;
  }

}).call(this);

},{"./persistence":6}],8:[function(require,module,exports){
(function() {
  var Budget, ModelMixin, remix, _ref,
    __slice = [].slice;

  _ref = require('./tasks'), Budget = _ref.Budget, remix = _ref.remix;

  ModelMixin = require('./persistence');

  module.exports = function(app) {
    app.run(function($rootScope, $timeout) {
      var apply, counter, oldAjax;
      oldAjax = Parse._ajax;
      counter = 0;
      apply = function() {
        counter--;
        if (counter <= 0) {
          counter = 0;
          return $timeout(function() {
            $rootScope.$apply();
            return console.log("applied after Parse call");
          });
        }
      };
      return Parse._ajax = function() {
        var args, p;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        counter++;
        p = oldAjax.call.apply(oldAjax, [Parse].concat(__slice.call(args)));
        p.then(apply, apply);
        return p;
      };
    });
    return app.provider('budget', function() {
      var mode;
      mode = 'production';
      remix(ModelMixin.parseBgMixin);
      return {
        setMode: function(_mode) {
          mode = _mode;
          if (mode === 'debug') {
            console.log('switch to readonly');
            return remix(ModelMixin.parseReadonlyMixin);
          } else if (mode === 'local') {
            console.log('switch to memory');
            return remix(ModelMixin.memMixin);
          }
        },
        $get: function() {
          var budgetPromise;
          Budget.mode = mode;
          budgetPromise = new Parse.Promise();
          return {
            unload: function() {
              return budgetPromise = new Parse.Promise();
            },
            load: function() {
              Budget.load(function(err, b) {
                if (err) {
                  return budgetPromise.reject(err);
                } else {
                  return budgetPromise.resolve(b);
                }
              });
              return budgetPromise;
            },
            whenLoad: function() {
              return budgetPromise;
            },
            getStatusForCost: function(cost) {
              return Budget.getStatusForCost(cost);
            }
          };
        }
      };
    });
  };

}).call(this);

},{"./persistence":6,"./tasks":7}],9:[function(require,module,exports){
(function() {
  module.exports = function(app) {
    app.directive('taskSelectionList', function() {
      return {
        restrict: 'E',
        replace: true,
        scope: {
          selection: "=selection"
        },
        templateUrl: "actions.html",
        link: function(scope, el, attrs) {
          scope.options = scope.$parent.options;
          scope.toggleBooked = function() {
            return scope.selection.toggleBookingTask();
          };
          scope.toggleTask = function() {
            scope.selection.toggle();
            if (attrs.autoClose !== void 0) {
              return scope.selection.deselectAll();
            }
          };
          return scope.$watch(scope.selection.$watch(), function() {
            scope.taskBooked = scope.selection.isBooked();
            return scope.task = scope.selection.getSelectionAsTask();
          }, true);
        }
      };
    });
    return app.directive('taskActionsList', function() {
      return {
        restrict: 'E',
        replace: true,
        scope: {
          task: "=",
          booking: "="
        },
        templateUrl: "actions.html",
        link: function(scope, el, attrs) {
          scope.options = scope.$parent.options;
          scope.toggleBooked = function() {
            return scope.booking.toggle(scope.task);
          };
          scope.toggleTask = function() {
            return scope.task.toggle();
          };
          return scope.$watch((function() {
            var _base;
            return typeof (_base = scope.booking).include === "function" ? _base.include(scope.task) : void 0;
          }), function(newVal) {
            return scope.taskBooked = newVal;
          });
        }
      };
    });
  };

}).call(this);

},{}],10:[function(require,module,exports){
(function() {
  module.exports = function(app) {
    app.service('tasksSelection', function() {
      var Selection;
      Selection = (function() {
        function Selection() {
          this.tasks = [];
        }

        Selection.prototype.toggleSelection = function(task) {
          var idx;
          idx = this.tasks.indexOf(task);
          if (idx === -1) {
            return this.tasks.push(task);
          } else {
            return this.tasks.splice(idx, 1);
          }
        };

        Selection.prototype.isSelected = function(task) {
          return this.tasks.indexOf(task) > -1;
        };

        Selection.prototype.hasOtherSelectedThan = function(task) {
          return this.tasks.length > 1 || this.tasks[0] !== task;
        };

        Selection.prototype.deselectAll = function() {
          return this.tasks.splice(0, this.tasks.length);
        };

        Selection.prototype["delete"] = function() {
          this.tasks.forEach(function(t) {
            return t.project.deleteTask(t);
          });
          return this.deselectAll();
        };

        Selection.prototype.$watch = function() {
          var _this = this;
          return function() {
            return _this.getSelectionAsTask();
          };
        };

        Selection.prototype.toggleBookingTask = function() {
          var booking, selectionBooked, tasksToToggle;
          if (this.tasks.length === 0) {
            return false;
          }
          booking = this.tasks[0].budget.booked;
          selectionBooked = this.isBooked();
          tasksToToggle = this.tasks.filter(function(t) {
            return booking.include(t) === selectionBooked;
          });
          return tasksToToggle.forEach(function(task) {
            return booking.toggle(task);
          });
        };

        Selection.prototype.toggle = function() {
          var nonCompleted, tasksToToggle;
          nonCompleted = this.tasks.filter(function(t) {
            return !t.is("completed");
          });
          tasksToToggle = nonCompleted.length === 0 ? this.tasks : nonCompleted;
          return tasksToToggle.forEach(function(task) {
            return task.toggle();
          });
        };

        Selection.prototype.isBooked = function() {
          var booking;
          if (this.tasks.length === 0) {
            return false;
          }
          booking = this.tasks[0].budget.booked;
          return this.tasks.every(function(t) {
            return booking.include(t);
          });
        };

        Selection.prototype.getSelectionAsTask = function() {
          var budget, nonCompleted, task;
          nonCompleted = this.tasks.filter(function(t) {
            return !t.is("completed");
          });
          task = {
            booked: this.isBooked()
          };
          if (nonCompleted.length === 0) {
            task.cost = this.tasks.map(function(t) {
              return t.cost;
            }).reduce((function(a, b) {
              return a + b;
            }), 0);
            task.status = "completed";
            task;
          } else {
            budget = nonCompleted[0].budget;
            task.cost = nonCompleted.map(function(t) {
              return t.cost;
            }).reduce((function(a, b) {
              return a + b;
            }), 0);
            task.status = budget.getStatusForCost(task.cost);
          }
          return task;
        };

        return Selection;

      })();
      return {
        createSelection: function() {
          return new Selection();
        }
      };
    });
    return app.directive('selectTo', function() {
      return function(scope, el, attrs) {
        var selection, useCtrl;
        selection = scope.$eval(attrs.selectTo);
        useCtrl = attrs.selectWith === 'ctrl-click';
        return el.click(function(e) {
          var objectToSelect;
          objectToSelect = scope.$eval(attrs.select);
          if (useCtrl && !e.ctrlKey && selection.hasOtherSelectedThan(objectToSelect)) {
            selection.deselectAll();
          }
          selection.toggleSelection(objectToSelect);
          return scope.$apply();
        });
      };
    });
  };

}).call(this);

},{}],11:[function(require,module,exports){
(function() {
  module.exports = function(app) {
    var LANG_KEY, addZeros, getDialog, setVal, toggle;
    setVal = function(scope, name, val) {
      var act;
      act = function() {
        return scope.$parent.$eval("" + name + " = " + val);
      };
      if (scope.$root.$$phase) {
        return act();
      } else {
        return scope.$apply(function() {
          return act();
        });
      }
    };
    toggle = function(scope, name) {
      return setVal(scope, name, "!" + name);
    };
    app.directive('dialogPanelTrigger', function() {
      return {
        scope: {
          dialogPanelTrigger: "@"
        },
        link: function(scope, el, attrs) {
          scope.$parent.$watch(attrs.dialogPanelTrigger, function(newVal) {
            if (newVal !== void 0) {
              return $(el).toggleClass('dialog-trigger-pressed', newVal);
            }
          });
          return $(el).click(function() {
            return toggle(scope, attrs.dialogPanelTrigger);
          });
        }
      };
    });
    getDialog = function(id) {
      return $("*[show-if=" + id + "]").data("dialog");
    };
    app.directive('dialogPanel', function() {
      return {
        transclude: true,
        restrict: 'E',
        replace: true,
        scope: {
          onSave: "&",
          onClose: "&",
          onHide: "&",
          saveButtonTitle: "=",
          cancelButtonTitle: "=",
          doNotClearForm: "@"
        },
        template: "<div class=\"dialog-panel\" ng-class=\"{shown: showIf}\">\n  <form class=\"clearfix\">\n    <div ng-transclude class='dialog-content'></div>\n    <div class='buttons'>\n      <button class='btn btn-primary' data-action=\"save\">{{ saveButtonTitle || 'Save' }}</button>\n      <button class='link' data-action=\"cancel\">{{ cancelButtonTitle || 'Close'}}</button>\n    </div>\n  </form>\n</div>",
        link: function(scope, el, attrs) {
          var dialog;
          dialog = {
            form: el.find("form"),
            origin: el.parent(),
            _show: function() {
              scope.showIf = true;
              return setTimeout((function() {
                var ie_is_bad;
                try {
                  return el.find("input")[0].focus();
                } catch (_error) {
                  ie_is_bad = _error;
                }
              }), 100);
            },
            showAt: function(element) {
              var _this = this;
              if (el.parent[0] !== element[0]) {
                element.append(el);
              }
              return setTimeout((function() {
                _this._show();
                return scope.$apply();
              }), 0);
            },
            show: function() {
              return this.showAt(this.origin);
            },
            hide: function(callSave, callCancel) {
              scope.showIf = false;
              if (callSave && scope.onSave) {
                scope.onSave();
              }
              if (callCancel && scope.onClose) {
                scope.onClose();
              }
              if (scope.onHide) {
                return scope.onHide();
              }
            },
            hideIfAt: function(element) {
              if (el.parent()[0] === element[0]) {
                return this.hide();
              }
            },
            save: function() {
              this.hide(true);
              return this.clearForm();
            },
            cancel: function() {
              this.hide(false, true);
              return this.clearForm();
            },
            clearForm: function() {
              if (attrs.doNotClearForm !== void 0) {
                return;
              }
              return this.form.find("input,textarea").val("");
            }
          };
          scope.$parent.$watch(attrs.showIf, function(newVal) {
            if (newVal) {
              return dialog.show();
            } else {
              return dialog.hide();
            }
          });
          el.find("*[data-action=save]").click(function() {
            dialog.save();
            return scope.$apply();
          });
          el.find("*[data-action=cancel]").click(function() {
            dialog.cancel();
            return scope.$apply();
          });
          return el.data("dialog", dialog);
        }
      };
    });
    app.directive("deleteTo", function() {
      return {
        link: function(scope, el, attrs) {
          var cls, deleteTo;
          cls = "" + attrs.deleteTo + "-item";
          $(el).addClass(cls).draggable({
            revert: true,
            opacity: 0.8
          });
          $(el).on("dragstart", function() {
            return $(el).addClass(cls);
          });
          $(el).data("onDrop", function() {
            if (attrs.onDelete) {
              return scope.$apply(function() {
                return scope.$eval(attrs.onDelete);
              });
            }
          });
          deleteTo = $("." + attrs.deleteTo);
          return deleteTo.droppable({
            accept: "." + cls,
            tolerance: "touch",
            hoverClass: "ready-to-drop",
            activate: function() {
              return deleteTo.addClass("drop-here");
            },
            deactivate: function() {
              return deleteTo.removeClass("drop-here");
            },
            drop: function(e, ui) {
              ui.draggable.data("onDrop")();
              return true;
            }
          });
        }
      };
    });
    app.directive('currency', function() {
      return {
        template: "<span class='currency'>{{budget.currency}}</span>",
        restrict: 'E'
      };
    });
    app.directive('countdown', function() {
      return function(scope, el, attrs) {
        var inFocus, setElVal, target, to, val;
        to = null;
        target = null;
        val = 0;
        inFocus = false;
        setElVal = function(val) {
          if (el.is("input")) {
            return el.val(val);
          } else {
            return el.text(val + "");
          }
        };
        el.on('focus', function() {
          return inFocus = true;
        }).on('blur', function() {
          return inFocus = false;
        });
        return scope.$watch(attrs.countdown, function(newVal) {
          var doStep;
          clearTimeout(to);
          if (inFocus) {
            return;
          }
          target = parseInt(newVal);
          if (isNaN(target)) {
            target = 0;
          }
          el.addClass("start-counting");
          doStep = function() {
            var step, _ref;
            if (inFocus) {
              val = target;
            }
            if (target === val) {
              el.removeClass("start-counting");
              setElVal(target);
              return;
            }
            step = (_ref = scope.$eval(attrs.step)) != null ? _ref : 1;
            if (target > val) {
              val += step;
              if (val > target) {
                val = target;
              }
            } else {
              val -= step;
              if (val < target) {
                val = target;
              }
            }
            setElVal(val);
            return to = setTimeout(doStep, 10);
          };
          return doStep();
        });
      };
    });
    app.directive('uiTitle', function() {
      return function(scope, el, attrs) {
        return el.tooltip({
          placement: "right",
          title: function() {
            return attrs.uiTitle;
          }
        });
      };
    });
    addZeros = function(num, amount) {
      var str;
      str = num + '';
      while (str.length < amount) {
        str = '0' + str;
      }
      return str;
    };
    app.filter('cost', function() {
      return function(input) {
        var div, parts, rem;
        parts = [];
        div = parseFloat(input);
        if (isNaN(div)) {
          div = 0;
        }
        if (div === 0) {
          return 0;
        }
        while (div > 0) {
          rem = div % 1000;
          div = div / 1000 | 0;
          parts.unshift(div > 0 ? addZeros(rem, 3) : rem);
        }
        return parts.join(' ');
      };
    });
    LANG_KEY = 'NIH_language';
    app.directive('langSelector', function(grService) {
      return {
        replace: true,
        restrict: 'E',
        templateUrl: 'partial/language-selector.html',
        link: function(scope, el, attrs) {
          var _ref;
          scope.languages = ['en', 'ru'];
          scope.$on('gr-lang-changed', function(e, lang) {
            scope.currentLanguage = lang;
            return localStorage[LANG_KEY] = lang;
          });
          scope.currentLanguage = grService.language;
          scope.changeLanguage = function(lang) {
            return grService.setLanguage(lang);
          };
          return grService.setLanguage((_ref = localStorage[LANG_KEY]) != null ? _ref : grService.language);
        }
      };
    });
    app.directive('longClick', function() {
      return {
        link: function(scope, el, attr) {
          var processingByOurClick;
          processingByOurClick = false;
          el.addClass('long-click');
          el.click(function() {
            processingByOurClick = true;
            el.addClass('processing');
            return scope.$apply(attr.longClick);
          });
          return scope.$watch(attr.processing, function(newVal) {
            if (newVal) {
              if (!processingByOurClick) {
                return el.attr('disabled', 'disabled');
              }
            } else {
              el.removeClass('processing');
              el.removeAttr('disabled');
              return processingByOurClick = false;
            }
          });
        }
      };
    });
    return {
      getDialog: getDialog
    };
  };

}).call(this);

},{}]},{},[1,2,3,5,6,4,8,7,9,10,11])
;