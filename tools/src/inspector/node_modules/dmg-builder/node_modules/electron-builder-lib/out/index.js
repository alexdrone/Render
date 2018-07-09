"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "getArchSuffix", {
  enumerable: true,
  get: function () {
    return _builderUtil().getArchSuffix;
  }
});
Object.defineProperty(exports, "Arch", {
  enumerable: true,
  get: function () {
    return _builderUtil().Arch;
  }
});
Object.defineProperty(exports, "archFromString", {
  enumerable: true,
  get: function () {
    return _builderUtil().archFromString;
  }
});
Object.defineProperty(exports, "Packager", {
  enumerable: true,
  get: function () {
    return _packager().Packager;
  }
});
Object.defineProperty(exports, "PublishManager", {
  enumerable: true,
  get: function () {
    return _PublishManager().PublishManager;
  }
});
Object.defineProperty(exports, "Platform", {
  enumerable: true,
  get: function () {
    return _core().Platform;
  }
});
Object.defineProperty(exports, "Target", {
  enumerable: true,
  get: function () {
    return _core().Target;
  }
});
Object.defineProperty(exports, "DIR_TARGET", {
  enumerable: true,
  get: function () {
    return _core().DIR_TARGET;
  }
});
Object.defineProperty(exports, "DEFAULT_TARGET", {
  enumerable: true,
  get: function () {
    return _core().DEFAULT_TARGET;
  }
});
Object.defineProperty(exports, "AppInfo", {
  enumerable: true,
  get: function () {
    return _appInfo().AppInfo;
  }
});
Object.defineProperty(exports, "CancellationToken", {
  enumerable: true,
  get: function () {
    return _builderUtilRuntime().CancellationToken;
  }
});
Object.defineProperty(exports, "PlatformPackager", {
  enumerable: true,
  get: function () {
    return _platformPackager().PlatformPackager;
  }
});
Object.defineProperty(exports, "buildForge", {
  enumerable: true,
  get: function () {
    return _forgeMaker().buildForge;
  }
});
exports.build = void 0;

function _bluebirdLst() {
  const data = require("bluebird-lst");

  _bluebirdLst = function () {
    return data;
  };

  return data;
}

function _promise() {
  const data = require("builder-util/out/promise");

  _promise = function () {
    return data;
  };

  return data;
}

function _builderUtil() {
  const data = require("builder-util");

  _builderUtil = function () {
    return data;
  };

  return data;
}

function _packager() {
  const data = require("./packager");

  _packager = function () {
    return data;
  };

  return data;
}

function _PublishManager() {
  const data = require("./publish/PublishManager");

  _PublishManager = function () {
    return data;
  };

  return data;
}

function _core() {
  const data = require("./core");

  _core = function () {
    return data;
  };

  return data;
}

function _appInfo() {
  const data = require("./appInfo");

  _appInfo = function () {
    return data;
  };

  return data;
}

function _builderUtilRuntime() {
  const data = require("builder-util-runtime");

  _builderUtilRuntime = function () {
    return data;
  };

  return data;
}

function _platformPackager() {
  const data = require("./platformPackager");

  _platformPackager = function () {
    return data;
  };

  return data;
}

function _forgeMaker() {
  const data = require("./forge-maker");

  _forgeMaker = function () {
    return data;
  };

  return data;
}

let build = (() => {
  var _ref = (0, _bluebirdLst().coroutine)(function* (options, packager = new (_packager().Packager)(options)) {
    // because artifact event maybe dispatched several times for different publish providers
    const artifactPaths = new Set();
    packager.artifactCreated(event => {
      if (event.file != null) {
        artifactPaths.add(event.file);
      }
    });
    const publishManager = new (_PublishManager().PublishManager)(packager, options);

    const sigIntHandler = () => {
      _builderUtil().log.warn("cancelled by SIGINT");

      packager.cancellationToken.cancel();
      publishManager.cancelTasks();
    };

    process.once("SIGINT", sigIntHandler);
    return yield (0, _promise().executeFinally)(packager.build().then(() => Array.from(artifactPaths)), errorOccurred => {
      let promise;

      if (errorOccurred) {
        publishManager.cancelTasks();
        promise = Promise.resolve(null);
      } else {
        promise = publishManager.awaitTasks();
      }

      return promise.then(() => process.removeListener("SIGINT", sigIntHandler));
    });
  });

  return function build(_x) {
    return _ref.apply(this, arguments);
  };
})(); exports.build = build;
//# sourceMappingURL=index.js.map