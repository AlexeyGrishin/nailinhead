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
  var Backend, Me, Project;

  Project = Parse.Object.extend("Project");

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
    },
    getProjects: function(cb) {
      var pq,
        _this = this;
      pq = new Parse.Query(Project);
      pq.equalTo("owner", Parse.User.current());
      pq.ascending("createdAt");
      return pq.find(this.defaultHandler(function(projects) {
        _this.projects = projects;
        return cb(projects.map(function(p) {
          return p.toJSON();
        }));
      }));
    },
    addProject: function(projectData, cb) {
      var project;
      project = new Project(projectData);
      project.set("owner", Parse.User.current());
      project.setACL(new Parse.ACL(Parse.User.current()));
      return project.save(null, this.defaultHandler(function(project) {
        return cb(project.toJSON());
      }));
    },
    saveProject: function(projectData, cb) {
      var projectObject;
      if (projectData.completed) {
        projectData = projectData;
      }
      projectObject = new Project(projectData);
      return projectObject.save(null, this.defaultHandler(cb));
    },
    deleteProject: function(projectData, cb) {
      var projectObject;
      projectObject = new Project(projectData);
      return projectObject.destroy(this.defaultHandler(cb));
    },
    fetchProject: function(projectData, cb) {
      var projectObject;
      projectObject = new Project(projectData);
      return projectObject.fetch(this.defaultHandler(function(project) {
        return cb(project.toJSON());
      }));
    },
    getOptions: function(cb) {
      return cb(Me().get("options"));
    },
    setOptions: function(options, cb) {
      Me().set("options", options);
      return Me().save(this.defaultHandler(cb));
    },
    saveCurrentUser: function(cb) {
      return Me().save(this.defaultHandler(cb));
    },
    getBudget: function(cb) {
      return cb(Me().get("budget"));
    },
    setBudget: function(budget, cb) {
      Me().set("budget", budget);
      return Me().save(this.defaultHandler(cb));
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
  var app, createTasksService, getDialog, localStorage;

  createTasksService = require('./tasks/tasks');

  app = angular.module('puzzle', []);

  localStorage = require('./tasks/localStorage');

  (require('./backend/parse_angular'))(app);

  app.service('tasksService', function(backend) {
    var tasksService;
    tasksService = createTasksService(backend);
    backend.init();
    return tasksService;
  });

  require('./test');

  getDialog = (require('./ui'))(app).getDialog;

  (require('./async'))(app);

  (require('./auth/auth'))(app);

  app.controller('global', function($scope, tasksService, backend, auth, $location) {
    $scope.loading = true;
    tasksService.onLoad(function() {
      return $scope.loading = false;
    });
    $scope.options = tasksService.options;
    $scope.auth = auth;
    $scope.$on('auth:loggedIn', function() {
      console.log("load tasks");
      return tasksService.load(function(error) {
        if (error) {
          console.error(error);
        }
        return $scope.$apply();
      });
    });
    $scope.$on('auth:loginFailed', function() {
      return $location.path("/auth");
    });
    $scope.logout = function() {
      return auth.logout(function() {});
    };
    return auth.check();
  });

  app.controller('header', function($scope, tasksService) {
    $scope.budget = tasksService.budget;
    $scope.$watch('currency', function(newVal) {
      if (!$scope.auth.loggedIn) {
        return;
      }
      if (newVal) {
        return tasksService.setCurrency(newVal);
      }
    });
    return $scope.$watch('budget.amount', function(newVal) {
      if (!$scope.auth.loggedIn) {
        return;
      }
      return tasksService.setBudget(newVal);
    });
  });

  app.config(function($routeProvider) {
    $routeProvider.when('/', {
      controller: 'projects',
      templateUrl: './projects.html'
    });
    $routeProvider.when('/auth', {
      controller: 'login',
      templateUrl: './login.html'
    });
    return $routeProvider.when('/:project', {
      controller: 'project',
      templateUrl: './project.html'
    });
  });

  app.controller('login', function($scope, auth, $location) {
    var onLogReg;
    $scope.auth = auth;
    onLogReg = function(user, error) {
      if (user) {
        $location.path("/");
      } else {
        $scope.error = error;
      }
      return $scope.$apply();
    };
    $scope.register = function() {
      return auth.register($scope.auth.username, $scope.auth.password, {
        options: {
          currency: "RUR"
        },
        budget: {
          amount: 10000
        }
      }, onLogReg);
    };
    return $scope.login = function() {
      return auth.login($scope.auth.username, $scope.auth.password, onLogReg);
    };
  });

  app.controller('projects', function(tasksService, $scope, $location) {
    $scope.projects = tasksService.projects;
    $scope.newProject = {
      title: ""
    };
    $scope.addProject = function() {
      if ($scope.newProject.title) {
        tasksService.addProject($scope.newProject.title, "/img/pic1.jpg", function(proj) {
          return $scope.$apply(function() {
            return $location.path("/" + proj.objectId);
          });
        });
      }
      return $scope.$apply();
    };
    return $scope.deleteProject = function(project) {
      return tasksService.deleteProject(project, function() {
        return $scope.$apply();
      });
    };
  });

  app.controller('project', function(tasksService, $scope, $routeParams) {
    var projectId;
    $scope.actionTitle = {
      available: "Upgrade",
      completed: "Downgrade",
      unavailable: "Locked"
    };
    projectId = $routeParams.project;
    tasksService.onLoad(function() {
      tasksService.selectProject(projectId);
      tasksService.updateStatus();
      $scope.project = tasksService.project;
      if ($scope.project.tasks.length === 0) {
        $scope.addTaskDialog = true;
      }
      if (!$scope.$$phase) {
        return $scope.$apply();
      }
    });
    $scope.currentTask = {};
    $scope.newTask = {
      title: ""
    };
    $scope.addTask = function() {
      if ($scope.newTask.title) {
        tasksService.addTask($scope.newTask.title, $scope.newTask.cost);
      }
      return setTimeout((function() {
        $scope.addTaskDialog = true;
        return $scope.$apply();
      }), 0);
    };
    $scope.deleteTask = function(task) {
      return tasksService.deleteTask(task);
    };
    $scope.toggleTask = function(task) {
      return tasksService.toggle(task);
    };
    $scope.taskInEdit = null;
    $scope.editTask = function(task) {
      var wasEdited;
      wasEdited = $scope.isInEdit(task);
      $scope.cancelEdit();
      if (wasEdited) {
        return;
      }
      return $scope.taskInEdit = {
        original: task,
        edited: $.extend({}, task)
      };
    };
    $scope.cancelEdit = function() {
      return $scope.taskInEdit = null;
    };
    $scope.saveTask = function(task) {
      task.title = $scope.taskInEdit.edited.title;
      task.cost = $scope.taskInEdit.edited.cost;
      tasksService.saveTask(task);
      return $scope.cancelEdit();
    };
    return $scope.isInEdit = function(task) {
      var _ref;
      return ((_ref = $scope.taskInEdit) != null ? _ref.original : void 0) === task;
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
            rest = total - maxAmountOfTasks - 1;
            tasksToShow.push({
              title: "Show the rest " + rest + " tasks",
              status: "more",
              text: "..."
            });
          }
          return tasksToShow;
        };
        return {
          toggle: function(task) {
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

  app.directive('projectThumb', function(tasksService, projectThumbModel, $location) {
    return {
      scope: {
        project: "=projectThumb"
      },
      replace: true,
      template: "<div class=\"project\">\n  <div class=\"task-thumb {{task.status}}\"\n       ng-repeat=\"task in thumb.tasksToShow\"\n       ui-title=\"{{options.currency}} {{task.cost}}\"\n       ng-click=\"click(task)\"\n        >\n        {{task.title}}\n  </div>\n  <div class=\"progress\">\n    <span ng-repeat=\"progress in thumb.progressToShow\"\n          class=\"{{progress.name}}\"\n          ui-title=\"{{progress.amount}} {{progress.title}}\"\n          style=\"width: {{progress.percent + '%'}}\"></span>\n  </div>\n  <strong><a href=\"#/{{project.objectId}}\">{{project.name}}</a></strong>\n</div>",
      link: function(scope, el, attrs) {
        var _ref;
        scope.thumb = projectThumbModel.create(scope.project, (_ref = attrs.thumbs) != null ? _ref : 9, scope.thumb);
        return scope.click = function(task) {
          if (task.status === "more") {
            return $location.path("/" + scope.project.objectId);
          } else if (task.status !== "unavailable") {
            tasksService.toggle(task);
            return scope.thumb.toggle(task);
          }
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

  app.directive('editTask', function() {
    return function(scope, el, attrs) {};
  });

}).call(this);

},{"./async":1,"./auth/auth":2,"./backend/parse_angular":4,"./tasks/localStorage":8,"./tasks/tasks":9,"./test":10,"./ui":11}],6:[function(require,module,exports){
(function() {
  var BOTTOM, IN, LEFT, OUT, PLAIN, RIGHT, TOP, distributePartsOnPicture, drawSquareWithPattern, fitInSquare, generatePuzzle, p, puzzle, rectangle, size, splitPicture, square, _ref;

  p = function(x, y) {
    return {
      x: x,
      y: y
    };
  };

  size = function(w, h) {
    return {
      w: w,
      h: h
    };
  };

  rectangle = function(p1, sz) {
    return {
      x: p1.x,
      y: p1.y,
      w: sz.w,
      h: sz.h,
      resize: function(delta) {
        return rectangle(p(this.x - delta, this.y - delta), size(this.w + delta, this.h + delta));
      },
      draw: function(ctx) {
        return ctx.rect(this.x, this.y, this.w, this.h);
      }
    };
  };

  square = function(x, y, s) {
    return rectangle(p(x, y), size(s, s));
  };

  drawSquareWithPattern = function(ctx, leftTop, size, pattern) {
    ctx.save();
    ctx.translate(leftTop.x, leftTop.y);
    pattern(ctx, "top");
    ["right", "bottom", "left"].forEach(function(dir, idx) {
      ctx.translate(size, 0);
      ctx.rotate(Math.PI / 2);
      return pattern(ctx, dir);
    });
    return ctx.restore();
  };

  PLAIN = "-";

  IN = "_";

  OUT = "^";

  _ref = [0, 1, 2, 3], LEFT = _ref[0], TOP = _ref[1], RIGHT = _ref[2], BOTTOM = _ref[3];

  puzzle = function(p1, sz, sizeOfPad, configuration) {
    var bottom, delta, left, obj, onOut, right, top;
    if (configuration == null) {
      configuration = "^_^_";
    }
    delta = {
      "_": sizeOfPad,
      "^": -sizeOfPad,
      "-": 0
    };
    left = configuration[0], top = configuration[1], right = configuration[2], bottom = configuration[3];
    if (sz.w !== sz.h) {
      throw new Error("Cannot create puzzle for non-square size: " + sz);
    }
    obj = {
      x: p1.x,
      y: p1.y,
      w: sz.w,
      h: sz.h,
      resize: function(delta) {
        return puzzle(p(p1.x - delta, p1.y - delta), size(sz.w + delta, sz.h + delta), sizeOfPad + delta, configuration);
      },
      draw: function(ctx) {
        var edgeSize, padFromCorner;
        edgeSize = sz.w;
        padFromCorner = (edgeSize - sizeOfPad * 2) / 2;
        ctx.save();
        drawSquareWithPattern(ctx, p1, edgeSize, function(ctx, dir) {
          var dy;
          if (dir === "top") {
            ctx.moveTo(0, 0);
          }
          ctx.lineTo(padFromCorner, 0);
          dy = delta[{
            left: left,
            top: top,
            right: right,
            bottom: bottom
          }[dir]];
          ctx.arcTo(padFromCorner, dy, edgeSize / 2, dy, sizeOfPad);
          ctx.arcTo(edgeSize - padFromCorner, dy, edgeSize - padFromCorner, 0, sizeOfPad);
          return ctx.lineTo(edgeSize, 0);
        });
        return ctx.restore();
      }
    };
    onOut = function(val) {
      return {
        addW: function() {
          if (val === OUT) {
            obj.w += sizeOfPad;
          }
          return this;
        },
        addH: function() {
          if (val === OUT) {
            obj.h += sizeOfPad;
          }
          return this;
        },
        shiftX: function() {
          if (val === OUT) {
            obj.x -= sizeOfPad;
          }
          return this;
        },
        shiftY: function() {
          if (val === OUT) {
            obj.y -= sizeOfPad;
          }
          return this;
        }
      };
    };
    onOut(left).addW().shiftX();
    onOut(right).addW();
    onOut(top).addH().shiftY();
    onOut(bottom).addH();
    return obj;
  };

  generatePuzzle = function(rows, cols, items) {
    var checkCorner, count, invert, lastCol, puzzleMap, random, _i, _results;
    count = items.length;
    invert = function(o) {
      switch (o) {
        case OUT:
          return IN;
        case IN:
          return OUT;
        default:
          return PLAIN;
      }
    };
    random = function() {
      return [IN, OUT][Math.round(Math.random())];
    };
    lastCol = items.length % cols;
    checkCorner = function(configuration, row, col, idx) {
      if (row === 0) {
        configuration[TOP] = PLAIN;
      }
      if (row === rows - 1 || (row === rows - 2 && lastCol > 0 && col >= lastCol) || idx === count - 1) {
        configuration[BOTTOM] = PLAIN;
      }
      if (col === 0) {
        configuration[LEFT] = PLAIN;
      }
      if (col === cols - 1 || idx === count - 1) {
        return configuration[RIGHT] = PLAIN;
      }
    };
    puzzleMap = (function() {
      _results = [];
      for (var _i = 0; 0 <= rows ? _i < rows : _i > rows; 0 <= rows ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).map(function() {
      var _i, _results;
      return (function() {
        _results = [];
        for (var _i = 0; 0 <= cols ? _i < cols : _i > cols; 0 <= cols ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this).map(function() {
        return {};
      });
    });
    items.forEach(function(_arg) {
      var col, row;
      col = _arg.col, row = _arg.row;
      puzzleMap[row][col].bottom = random();
      return puzzleMap[row][col].right = random();
    });
    return items.map(function(item, idx) {
      var col, configuration, row;
      row = item.row;
      col = item.col;
      configuration = ["-", "-", "-", "-"];
      configuration[BOTTOM] = puzzleMap[row][col].bottom;
      if (row > 0) {
        configuration[TOP] = invert(puzzleMap[row - 1][col].bottom);
      }
      configuration[RIGHT] = puzzleMap[row][col].right;
      if (col > 0) {
        configuration[LEFT] = invert(puzzleMap[row][col - 1].right);
      }
      checkCorner(configuration, row, col, idx);
      console.log("" + item.data.title + " at " + row + ", " + col + ", " + (col === cols - 1) + ", " + (configuration.join('')));
      configuration = configuration.join("");
      return {
        col: col,
        row: row,
        configuration: configuration
      };
    });
  };

  fitInSquare = function(parts) {
    var cols, rows, sq;
    if (parts.length !== void 0) {
      parts = parts.length;
    }
    sq = Math.ceil(Math.sqrt(parts));
    cols = sq;
    rows = Math.ceil(parts / cols);
    return {
      cols: cols,
      rows: rows
    };
  };

  distributePartsOnPicture = function(newObjects, oldParts, oldCols, oldRows) {
    var addToNewRowOrCol, busyCells, cols, objects, parts, rows, _i, _ref1, _results;
    if (oldParts == null) {
      oldParts = [];
    }
    if (oldCols == null) {
      oldCols = 0;
    }
    if (oldRows == null) {
      oldRows = 0;
    }
    _ref1 = fitInSquare(oldParts.length + newObjects.length), cols = _ref1.cols, rows = _ref1.rows;
    busyCells = [];
    oldParts.forEach(function(_arg) {
      var col, row, _ref2;
      col = _arg.col, row = _arg.row;
      busyCells[row] = (_ref2 = busyCells[row]) != null ? _ref2 : [];
      return busyCells[row][col] = true;
    });
    parts = oldParts.slice();
    objects = newObjects.slice();
    addToNewRowOrCol = cols > oldCols || rows > oldRows;
    (function() {
      _results = [];
      for (var _i = 0; 0 <= rows ? _i < rows : _i > rows; 0 <= rows ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).forEach(function(row) {
      var _i, _results;
      if (objects.length === 0) {
        return;
      }
      return (function() {
        _results = [];
        for (var _i = 0; 0 <= cols ? _i < cols : _i > cols; 0 <= cols ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this).forEach(function(col) {
        var _ref2;
        if (objects.length === 0) {
          return;
        }
        if ((_ref2 = busyCells[row]) != null ? _ref2[col] : void 0) {
          return;
        }
        if (addToNewRowOrCol && row < oldRows && col < oldCols) {
          return;
        }
        return parts.push({
          data: objects.shift(),
          row: row,
          col: col
        });
      });
    });
    if (objects.length > 0) {
      throw new Error("Cannot locate objects: " + objects);
    }
    return {
      cols: cols,
      rows: rows,
      parts: parts
    };
  };

  splitPicture = function(width, height, pad, objects, oldParts) {
    var cols, generateFigure, generator, oldCols, oldRows, partSize, parts, puzzleGenerator, realheight, realwidth, rows, squareGenerator, startx, starty, _ref1, _ref2, _ref3;
    if (oldParts == null) {
      oldParts = [];
    }
    squareGenerator = function(rows, cols, objects) {
      return function(x, y, partSize, col, row) {
        return square(x, y, partSize);
      };
    };
    puzzleGenerator = function(rows, cols, objects) {
      var puzzleItems;
      puzzleItems = generatePuzzle(rows, cols, objects);
      return function(x, y, partSize, col, row) {
        return puzzle(p(x, y), size(partSize, partSize), partSize / 4, puzzleItems.filter(function(pi) {
          return pi.col === col && pi.row === row;
        })[0].configuration);
      };
    };
    generator = puzzleGenerator;
    realwidth = width - 2 * pad;
    realheight = height - 2 * pad;
    oldCols = (_ref1 = 1 + Math.max.apply(null, oldParts.map(function(o) {
      return o.col;
    }))) != null ? _ref1 : 0;
    oldRows = (_ref2 = 1 + Math.max.apply(null, oldParts.map(function(o) {
      return o.row;
    }))) != null ? _ref2 : 0;
    _ref3 = distributePartsOnPicture(objects, oldParts, oldCols, oldRows), cols = _ref3.cols, rows = _ref3.rows, parts = _ref3.parts;
    partSize = Math.min(realwidth / cols, realheight / rows);
    startx = (realwidth - partSize * cols) / 2 + pad;
    starty = (realheight - partSize * rows) / 2 + pad;
    generateFigure = generator(rows, cols, parts);
    return {
      size: partSize,
      parts: parts.map(function(part, idx) {
        part.figure = generateFigure(part.col * partSize + startx, part.row * partSize + starty, partSize, part.col, part.row);
        return part;
      })
    };
  };

  module.exports = {
    p: p,
    size: size,
    splitPicture: splitPicture
  };

}).call(this);

},{}],7:[function(require,module,exports){
(function() {
  var c, clearPuzzlePiece, clipFigure, context, drawImageWithGrid, drawPuzzlePiece, loadImage, makePuzzlePiece, sizeToScale, toScale;

  c = require('./calc');

  loadImage = function(image, cb) {
    var img;
    if (typeof image === 'string') {
      img = new Image();
      img.src = image;
      return img.onload = function() {
        return cb(img);
      };
    } else {
      return cb(image);
    }
  };

  context = function(canvas) {
    canvas.ctx = canvas.getContext("2d");
    return canvas.ctx;
  };

  drawImageWithGrid = function(canvas, image, split) {
    return loadImage(image, function(image) {
      var ctx, func, part, _i, _len, _ref, _results;
      canvas.width = image.width;
      canvas.height = image.height;
      ctx = context(canvas);
      ctx.drawImage(image, 0, 0);
      _ref = split.parts;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        part = _ref[_i];
        func = part.visible ? drawPuzzlePiece : clearPuzzlePiece;
        _results.push(func(canvas, image, part.figure, part.figure.x, part.figure.y));
      }
      return _results;
    });
  };

  clipFigure = function(_arg, _arg1, figure, whenClip) {
    var ctx, scale, x, y;
    ctx = _arg.ctx;
    x = _arg1.x, y = _arg1.y, scale = _arg1.scale;
    ctx.save();
    ctx.beginPath();
    if (scale) {
      ctx.scale(scale, scale);
    }
    ctx.translate(-figure.x + x, -figure.y + y);
    figure.draw(ctx);
    ctx.clip();
    whenClip();
    return ctx.restore();
  };

  clearPuzzlePiece = function(_arg, image, part, x, y) {
    var ctx;
    ctx = _arg.ctx;
    if (x == null) {
      x = 0;
    }
    if (y == null) {
      y = 0;
    }
    ctx.fillStyle = "#ccc";
    ctx.beginPath();
    part.draw(ctx);
    return ctx.fill();
  };

  toScale = function(sizeScalar, newSize) {
    return newSize / sizeScalar;
  };

  sizeToScale = function(size, newSize) {
    return toScale(Math.max(size.w, size.h), newSize);
  };

  drawPuzzlePiece = function(canvas, image, part, options) {
    if (options == null) {
      options = {
        x: 0,
        y: 0
      };
    }
    return loadImage(image, function(image) {
      var clipOpts;
      clipOpts = {
        x: options.x,
        y: options.y
      };
      if (options.size) {
        clipOpts.scale = sizeToScale(part, options.size);
      }
      return clipFigure(canvas, clipOpts, part, function() {
        canvas.ctx.drawImage(image, 0, 0);
        canvas.ctx.strokeStyle = "#444";
        canvas.ctx.beginPath();
        part.draw(canvas.ctx);
        return canvas.ctx.stroke();
      });
    });
  };

  makePuzzlePiece = function(image, part, newSize) {
    var $canvas, canvas;
    $canvas = $("<canvas></canvas>").hide().appendTo($("body"));
    canvas = $canvas[0];
    context(canvas);
    loadImage(image, function(image) {
      canvas.width = newSize != null ? newSize : part.w;
      canvas.height = newSize != null ? newSize : part.h;
      return drawPuzzlePiece(canvas, image, part, {
        x: 0,
        y: 0,
        size: newSize
      });
    });
    return $canvas;
  };

  module.exports = {
    splitPicture: c.splitPicture.bind(c),
    drawPuzzlePiece: drawPuzzlePiece,
    drawImageWithGrid: drawImageWithGrid,
    loadImage: loadImage,
    makePuzzlePiece: makePuzzlePiece
  };

}).call(this);

},{"./calc":6}],8:[function(require,module,exports){
(function() {
  var Storage, parseSafe;

  parseSafe = function(val) {
    if (val === void 0) {
      return void 0;
    }
    return JSON.parse(val);
  };

  Storage = {
    getProjects: function(cb) {
      var _ref;
      return cb((_ref = parseSafe(typeof localStorage !== "undefined" && localStorage !== null ? localStorage.projects : void 0)) != null ? _ref : []);
    },
    getBudget: function(cb) {
      var _ref;
      return cb((_ref = parseSafe(typeof localStorage !== "undefined" && localStorage !== null ? localStorage.budget : void 0)) != null ? _ref : {});
    },
    getOptions: function(cb) {
      var _ref;
      return cb((_ref = parseSafe(typeof localStorage !== "undefined" && localStorage !== null ? localStorage.options : void 0)) != null ? _ref : {});
    },
    setOptions: function(options, cb) {
      if (cb == null) {
        cb = function() {};
      }
      if (localStorage) {
        localStorage.options = JSON.stringify(options);
      }
      return cb();
    },
    addProject: function(project, cb) {
      var _this = this;
      if (cb == null) {
        cb = function() {};
      }
      return this.getProjects(function(projects) {
        projects.push(project);
        return _this._saveProjects(projects, function() {
          return cb(project);
        });
      });
    },
    _findByID: function(projects, id) {
      return projects.filter(function(p) {
        return p.id === id;
      })[0];
    },
    deleteProject: function(project, cb) {
      var _this = this;
      if (cb == null) {
        cb = function() {};
      }
      return this.getProjects(function(projects) {
        projects.splice(_this._findByID(projects, project.id), 1);
        return _this._saveProjects(projects, function() {
          return cb(project);
        });
      });
    },
    _saveProjects: function(projects, cb) {
      if (cb == null) {
        cb = function() {};
      }
      if (localStorage) {
        return localStorage.projects = JSON.stringify(projects);
      }
    },
    saveProject: function(project, cb) {
      var _this = this;
      if (cb == null) {
        cb = function() {};
      }
      return this.getProjects(function(projects) {
        projects.splice(_this._findByID(projects, project.id), 1, project);
        return _this._saveProjects(projects, function() {
          return cb(project);
        });
      });
    },
    setBudget: function(budget, cb) {
      if (cb == null) {
        cb = function() {};
      }
      if (localStorage) {
        localStorage.budget = JSON.stringify(budget);
      }
      return cb();
    }
  };

  module.exports = Storage;

}).call(this);

},{}],9:[function(require,module,exports){
(function() {
  var Budget, Project, Task, TasksService, clear, parseString, task, toJSON,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty;

  Budget = (function() {
    function Budget(amount) {
      this.amount = amount;
    }

    Budget.prototype.set = function(amount) {
      this.amount = amount;
      this.amount = parseFloat(this.amount);
      if (isNaN(this.amount)) {
        return this.amount = 0;
      }
    };

    Budget.prototype.increase = function(delta) {
      return this.set(this.amount + parseFloat(delta));
    };

    Budget.prototype.decrease = function(delta) {
      return this.set(this.amount - parseFloat(delta));
    };

    Budget.prototype.isEnoughFor = function(money) {
      return money <= this.amount;
    };

    return Budget;

  })();

  Task = (function() {
    function Task(title, cost, status) {
      this.title = title;
      this.cost = cost != null ? cost : 0;
      this.status = status != null ? status : "";
    }

    Task.prototype.complete = function(budget) {
      if (this.status === "completed") {
        return;
      }
      if (this.status === !"available") {
        throw new Error("Task '" + this.title + "' cannot be done");
      }
      this.status = "completed";
      return budget.decrease(this.cost);
    };

    Task.prototype.updateStatus = function(budget) {
      var oldStatus;
      oldStatus = this.status;
      if (this.status === "completed") {
        return false;
      }
      this.status = budget.isEnoughFor(this.cost) ? "available" : "unavailable";
      return this.status !== oldStatus;
    };

    Task.prototype.revert = function(budget) {
      if (this.status === !"completed") {
        throw new Error("Task '" + this.title + "' cannot be undone - it is not completed");
      }
      this.status = "";
      budget.increase(this.cost);
      return this.updateStatus(budget);
    };

    Task.prototype.is = function(status) {
      return this.status === status;
    };

    return Task;

  })();

  task = function(title, cost, status) {
    return new Task(title, cost, status);
  };

  parseString = function(str, cost) {
    var ci, probablyCost;
    if (cost) {
      return {
        name: str,
        cost: cost
      };
    }
    if (str.indexOf(',') !== -1 || str.indexOf(' ') !== -1) {
      ci = Math.max(str.lastIndexOf(','), str.lastIndexOf(' '));
      probablyCost = parseFloat(str.substring(ci + 1).replace(/[^0-9.]/gi, ''));
      if (!isNaN(probablyCost)) {
        return {
          name: str.substring(0, ci),
          cost: probablyCost
        };
      }
    }
    return {
      name: str,
      cost: 0
    };
  };

  clear = function() {
    var obj, objs, _i, _len, _results;
    objs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    _results = [];
    for (_i = 0, _len = objs.length; _i < _len; _i++) {
      obj = objs[_i];
      if (obj.splice) {
        _results.push(obj.splice(0, obj.length));
      } else {
        _results.push(angular.copy({}, obj));
      }
    }
    return _results;
  };

  Project = (function() {
    function Project() {}

    Project.prototype.byStatus = function(status) {
      return this.tasks.filter(function(t) {
        return t.is(status);
      });
    };

    Project.prototype.completed = function() {
      return this.byStatus("completed");
    };

    Project.prototype.available = function() {
      return this.byStatus("available");
    };

    Project.prototype.unavailable = function() {
      return this.byStatus("unavailable");
    };

    return Project;

  })();

  toJSON = function(obj) {
    var key, newObj, val;
    newObj = angular.copy(obj);
    for (key in newObj) {
      if (!__hasProp.call(newObj, key)) continue;
      val = newObj[key];
      if ($.isFunction(val)) {
        delete newObj[key];
      }
    }
    return newObj;
  };

  TasksService = function(storage) {
    if (storage == null) {
      storage = require('./localStorage');
    }
    return {
      project: {},
      budget: new Budget(0),
      projects: [],
      options: {},
      loading: true,
      load: function(cb) {
        var _this = this;
        clear(this.project, this.projects, this.options);
        this.loading = true;
        return storage.getProjects(function(projects, error) {
          if (error) {
            return cb(error);
          }
          projects.forEach(function(p) {
            var proj;
            p.tasks = p.tasks.map(function(t) {
              return new Task(t.title, t.cost, t.status);
            });
            proj = new Project();
            angular.copy(p, proj);
            return _this.projects.push(proj);
          });
          return storage.getBudget(function(budget, error) {
            if (error) {
              return cb(error);
            }
            _this.setBudget(budget != null ? budget.amount : void 0);
            return storage.getOptions(function(options, error) {
              if (options) {
                angular.copy(options, _this.options);
              }
              if (error) {
                return cb(error);
              }
              storage.saveCurrentUser();
              _this.loading = false;
              $(_this).trigger("tasks.loaded");
              return cb();
            });
          });
        });
      },
      setCurrency: function(c, cb) {
        if (cb == null) {
          cb = function() {};
        }
        this.options.currency = c;
        return storage.setOptions(this.options, cb);
      },
      _nextId: function() {
        if (this.projects.length === 0) {
          return 1;
        }
        return 1 + (Math.max.apply(null, this.projects.map(function(p) {
          return p.id;
        })));
      },
      addProject: function(name, image, cb) {
        var proj,
          _this = this;
        if (cb == null) {
          cb = function() {};
        }
        proj = {
          name: name,
          image: image,
          tasks: []
        };
        return storage.addProject(proj, function(project) {
          _this.projects.push(new Project(project));
          return cb(project);
        });
      },
      deleteProject: function(project, cb) {
        var _this = this;
        if (cb == null) {
          cb = function() {};
        }
        return storage.deleteProject(project, function() {
          _this.projects.splice(_this.projects.indexOf(project), 1);
          return cb();
        });
      },
      getProject: function(id) {
        return this.projects.filter(function(p) {
          return p.objectId.toString() === id.toString();
        })[0];
      },
      onLoad: function(cb) {
        if (this.loading) {
          return $(this).on('tasks.loaded', cb);
        } else {
          return cb();
        }
      },
      selectProject: function(project_or_id, cb) {
        var name, project, value, _results;
        project = project_or_id.objectId ? project_or_id : this.getProject(project_or_id);
        _results = [];
        for (name in project) {
          value = project[name];
          _results.push(this.project[name] = value);
        }
        return _results;
      },
      unselectProject: function() {
        return this.project.objectId = null;
      },
      updateStatus: function() {
        if (!this.project.objectId) {
          return;
        }
        return this._updateProjectStatus(this.project);
      },
      _updateAllProjectStatuses: function(forceForTask) {
        var _this = this;
        if (forceForTask == null) {
          forceForTask = null;
        }
        return this.projects.forEach(function(p) {
          return _this._updateProjectStatus(p, forceForTask);
        });
      },
      _updateProjectStatus: function(project, forceForTask) {
        var updated,
          _this = this;
        if (forceForTask == null) {
          forceForTask = null;
        }
        updated = false;
        project.tasks.forEach(function(t) {
          if (t.updateStatus(_this.budget)) {
            return updated = true;
          }
        });
        if (updated || project.tasks.indexOf(forceForTask) !== -1) {
          return this._saveProject(project);
        }
      },
      _saveProject: function(project) {
        console.log("Save project " + project.name);
        if (project.objectId) {
          return storage.saveProject(toJSON(project));
        }
      },
      _saveCurrentProject: function() {
        if (this.project.objectId) {
          return storage.saveProject(toJSON(this.project));
        }
      },
      addTask: function(name, cost) {
        var t, _ref;
        if (!this.project.objectId) {
          return;
        }
        _ref = parseString(name, cost), name = _ref.name, cost = _ref.cost;
        t = task(name, cost);
        t.updateStatus(this.budget);
        return this._addTask(t);
      },
      deleteTask: function(task) {
        if (!this.project.objectId) {
          return;
        }
        this.project.tasks.splice(this.project.tasks.indexOf(task), 1);
        return this._saveCurrentProject();
      },
      _addTask: function(task) {
        this.project.tasks.push(task);
        this._saveCurrentProject();
        return task;
      },
      saveTask: function(task) {
        return this._saveCurrentProject();
      },
      toggle: function(task) {
        if (task.is("completed")) {
          task.revert(this.budget);
        } else if (task.is("available")) {
          task.complete(this.budget);
        } else {
          throw new Error("not.available");
        }
        return this._updateAllProjectStatuses(task);
      },
      setBudget: function(newValue) {
        this.budget.set(parseFloat(newValue));
        this._updateAllProjectStatuses();
        return storage.setBudget(this.budget);
      },
      getProjectProgress: function(project) {
        var completed, total;
        completed = project.tasks.filter(function(t) {
          return t.is("completed");
        }).length;
        total = project.tasks.length;
        if (total === 0) {
          return 0;
        } else {
          return 100 * completed / total;
        }
      }
    };
  };

  module.exports = TasksService;

}).call(this);

},{"./localStorage":8}],10:[function(require,module,exports){
(function() {
  var app, drawImageWithGrid, drawPuzzlePiece, loadImage, loadPuzzle, makePuzzlePiece, splitPicture, updatePartVisibility, _ref;

  _ref = require('./puzzle/puzzle'), drawImageWithGrid = _ref.drawImageWithGrid, splitPicture = _ref.splitPicture, drawPuzzlePiece = _ref.drawPuzzlePiece, loadImage = _ref.loadImage, makePuzzlePiece = _ref.makePuzzlePiece;

  app = angular.module('puzzle');

  updatePartVisibility = function(part) {
    return part.visible = part.data.is('completed');
  };

  loadPuzzle = function(puzzle, project, cb) {
    return loadImage(project.image, function(image) {
      puzzle.image = image;
      puzzle.split = splitPicture(image.width, image.height, 10, project.tasks);
      puzzle.split.parts.forEach(updatePartVisibility);
      return cb();
    });
  };

  app.controller('test', function(tasksService, $scope) {
    var updatePuzzle;
    $scope.puzzle = {};
    $scope.project = tasksService.project;
    $scope.budget = tasksService.budget;
    updatePuzzle = (function() {
      return loadPuzzle($scope.puzzle, $scope.project, function() {
        return $scope.$apply();
      });
    });
    $scope.$watch("project.id", updatePuzzle);
    $scope.toggleTask = function(part) {
      tasksService.toggle(part.data);
      return updatePartVisibility(part);
    };
    $scope.addTask = function() {
      var task;
      task = tasksService.addTask("New task", 33);
      $scope.puzzle.split = splitPicture($scope.puzzle.image.width, $scope.puzzle.image.height, 10, [task], $scope.puzzle.split.parts);
      return $scope.puzzle.split.parts.forEach(updatePartVisibility);
    };
    $scope.$watch("budget.amount", function() {
      return tasksService.updateStatus();
    });
    tasksService.selectProject(tasksService.projects[0]);
    return $scope.$watch("puzzle.split.parts", (function() {
      var $canvas;
      $canvas = $("canvas.project-img")[0];
      if (!$scope.puzzle.image) {
        return;
      }
      return drawImageWithGrid($canvas, $scope.puzzle.image, $scope.puzzle.split);
    }), true);
  });

  app.directive('puzzlePart', function() {
    return {
      replace: true,
      scope: {
        puzzlePart: '=puzzlePart',
        puzzlePartToggle: '&'
      },
      template: "<div\nng-click=\"puzzlePartToggle()\"\nng-class=\"{off: !puzzlePart.visible}\"\ntitle=\"{{ puzzlePart.data.title }}\"></div>",
      link: function(scope, el, attrs) {
        var piece;
        piece = null;
        return scope.$parent.$watch(attrs.puzzlePart, (function(newVal, oldVal) {
          var image, part, puzzle;
          part = newVal;
          if (!part) {
            return;
          }
          puzzle = scope.$parent.puzzle;
          image = attrs.puzzlePartNoImage ? new Image() : puzzle.image;
          if (!attrs.puzzlePartToggle) {
            scope.puzzlePartToggle = (function() {
              return part.visible = !part.visible;
            });
          }
          if (piece) {
            piece.remove();
          }
          piece = makePuzzlePiece(image, part.figure, attrs.puzzlePartSize).appendTo(el).show();
          if ($(el).css('position') === 'absolute') {
            return $(el).css({
              left: part.figure.x,
              top: part.figure.y
            });
          }
        }), true);
      }
    };
  });

}).call(this);

},{"./puzzle/puzzle":7}],11:[function(require,module,exports){
(function() {
  module.exports = function(app) {
    var getDialog, setVal, toggle;
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
            revert: true
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
              return ui.draggable.data("onDrop")();
            }
          });
        }
      };
    });
    app.directive('currency', function() {
      return {
        template: "<span class='currency'>{{options.currency}}</span>",
        restrict: 'E'
      };
    });
    app.directive('countdown', function() {
      return function(scope, el, attrs) {
        var inFocus, target, to, val;
        to = null;
        target = null;
        val = 0;
        inFocus = false;
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
          target = newVal;
          el.addClass("start-counting");
          doStep = function() {
            var step, _ref;
            if (inFocus) {
              val = target;
            }
            if (target === val) {
              el.removeClass("start-counting");
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
            el.val(val);
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
    return {
      getDialog: getDialog
    };
  };

}).call(this);

},{}]},{},[1,2,3,4,5,6,7,8,9,10,11])
;