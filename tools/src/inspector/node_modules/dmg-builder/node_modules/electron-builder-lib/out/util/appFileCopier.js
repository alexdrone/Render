"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getDestinationPath = getDestinationPath;
exports.copyFileOrData = copyFileOrData;
exports.copyAppFiles = void 0;

function _bluebirdLst() {
  const data = _interopRequireWildcard(require("bluebird-lst"));

  _bluebirdLst = function () {
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

function _fs() {
  const data = require("builder-util/out/fs");

  _fs = function () {
    return data;
  };

  return data;
}

function _fsExtraP() {
  const data = require("fs-extra-p");

  _fsExtraP = function () {
    return data;
  };

  return data;
}

var path = _interopRequireWildcard(require("path"));

function _fileTransformer() {
  const data = require("../fileTransformer");

  _fileTransformer = function () {
    return data;
  };

  return data;
}

function _AppFileCopierHelper() {
  const data = require("./AppFileCopierHelper");

  _AppFileCopierHelper = function () {
    return data;
  };

  return data;
}

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

function getDestinationPath(file, fileSet) {
  if (file === fileSet.src) {
    return fileSet.destination;
  } else {
    const src = (0, _AppFileCopierHelper().ensureEndSlash)(fileSet.src);
    const dest = (0, _AppFileCopierHelper().ensureEndSlash)(fileSet.destination);

    if (file.startsWith(src)) {
      return dest + file.substring(src.length);
    } else {
      // hoisted node_modules
      // not lastIndexOf, to ensure that nested module (top-level module depends on) copied to parent node_modules, not to top-level directory
      // project https://github.com/angexis/punchcontrol/commit/cf929aba55c40d0d8901c54df7945e1d001ce022
      const index = file.indexOf(_fileTransformer().NODE_MODULES_PATTERN);

      if (index < 0) {
        throw new Error(`File "${file}" not under the source directory "${fileSet.src}"`);
      }

      return dest + file.substring(index + 1
      /* leading slash */
      );
    }
  }
}

let copyAppFiles = (() => {
  var _ref = (0, _bluebirdLst().coroutine)(function* (fileSet, packager, transformer) {
    const metadata = fileSet.metadata;
    const transformedFiles = fileSet.transformedFiles; // search auto unpacked dir

    const taskManager = new (_builderUtil().AsyncTaskManager)(packager.cancellationToken);
    const createdParentDirs = new Set();

    function transformContentIfNeed(sourceFile, index) {
      let transformedContent = transformedFiles == null ? null : transformedFiles.get(index);

      if (transformedContent == null) {
        transformedContent = transformer(sourceFile);
      }

      if (transformedContent != null && typeof transformedContent === "object" && "then" in transformedContent) {
        return transformedContent;
      } else {
        return Promise.resolve(transformedContent);
      }
    }

    const fileCopier = new (_fs().FileCopier)();
    const links = [];

    for (let i = 0, n = fileSet.files.length; i < n; i++) {
      const sourceFile = fileSet.files[i];
      const stat = metadata.get(sourceFile);

      if (stat == null) {
        // dir
        continue;
      }

      const destinationFile = getDestinationPath(sourceFile, fileSet);

      if (stat.isSymbolicLink()) {
        links.push({
          file: destinationFile,
          link: yield (0, _fsExtraP().readlink)(sourceFile)
        });
        continue;
      }

      const fileParent = path.dirname(destinationFile);

      if (!createdParentDirs.has(fileParent)) {
        createdParentDirs.add(fileParent);
        yield (0, _fsExtraP().ensureDir)(fileParent);
      }

      taskManager.addTask(transformContentIfNeed(sourceFile, i).then(it => copyFileOrData(fileCopier, it, sourceFile, destinationFile, stat)));

      if (taskManager.tasks.length > _fs().MAX_FILE_REQUESTS) {
        yield taskManager.awaitTasks();
      }
    }

    if (taskManager.tasks.length > 0) {
      yield taskManager.awaitTasks();
    }

    if (links.length > 0) {
      yield _bluebirdLst().default.map(links, it => (0, _fsExtraP().symlink)(it.link, it.file), _fs().CONCURRENCY);
    }
  });

  return function copyAppFiles(_x, _x2, _x3) {
    return _ref.apply(this, arguments);
  };
})();

exports.copyAppFiles = copyAppFiles;

function copyFileOrData(fileCopier, data, source, destination, stats) {
  if (data == null) {
    return fileCopier.copy(source, destination, stats);
  } else {
    return (0, _fsExtraP().writeFile)(destination, data);
  }
} 
//# sourceMappingURL=appFileCopier.js.map