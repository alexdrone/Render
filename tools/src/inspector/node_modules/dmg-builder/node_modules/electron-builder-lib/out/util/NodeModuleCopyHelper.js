"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.NodeModuleCopyHelper = void 0;

function _bluebirdLst() {
  const data = _interopRequireWildcard(require("bluebird-lst"));

  _bluebirdLst = function () {
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

function _fileMatcher() {
  const data = require("../fileMatcher");

  _fileMatcher = function () {
    return data;
  };

  return data;
}

function _platformPackager() {
  const data = require("../platformPackager");

  _platformPackager = function () {
    return data;
  };

  return data;
}

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

const excludedFiles = new Set([".DS_Store", "node_modules"
/* already in the queue */
, "CHANGELOG.md", "ChangeLog", "changelog.md", "binding.gyp", ".npmignore"].concat(_fileMatcher().excludedNames.split(",")));
const topLevelExcludedFiles = new Set(["test.js", "karma.conf.js", ".coveralls.yml", "README.md", "readme.markdown", "README", "readme.md", "readme", "test", "__tests__", "tests", "powered-test", "example", "examples"]);
/** @internal */

class NodeModuleCopyHelper {
  constructor(matcher, packager) {
    this.matcher = matcher;
    this.packager = packager;
    this.metadata = new Map();
    this.filter = matcher.createFilter();
  }

  handleFile(file, fileStat) {
    if (!fileStat.isSymbolicLink()) {
      return null;
    }

    return (0, _fsExtraP().readlink)(file).then(linkTarget => {
      // http://unix.stackexchange.com/questions/105637/is-symlinks-target-relative-to-the-destinations-parent-directory-and-if-so-wh
      return this.handleSymlink(fileStat, file, path.resolve(path.dirname(file), linkTarget));
    });
  }

  handleSymlink(fileStat, file, linkTarget) {
    const link = path.relative(this.matcher.from, linkTarget);

    if (link.startsWith("..")) {
      // outside of project, linked module (https://github.com/electron-userland/electron-builder/issues/675)
      return (0, _fsExtraP().stat)(linkTarget).then(targetFileStat => {
        this.metadata.set(file, targetFileStat);
        return targetFileStat;
      });
    } else {
      fileStat.relativeLink = link;
    }

    return null;
  }

  collectNodeModules(list) {
    var _this = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const filter = _this.filter;
      const metadata = _this.metadata;
      const isIncludePdb = _this.packager.config.includePdb === true;
      const onNodeModuleFile = (0, _platformPackager().resolveFunction)(_this.packager.config.onNodeModuleFile);
      const result = [];
      const queue = [];

      for (const dep of list) {
        queue.length = 1;
        queue[0] = dep.path;

        if (dep.link != null) {
          _this.metadata.set(dep.path, dep.stat);

          const r = _this.handleSymlink(dep.stat, dep.path, dep.link);

          if (r != null) {
            yield r;
          }
        }

        while (queue.length > 0) {
          const dirPath = queue.pop();
          const childNames = yield (0, _fsExtraP().readdir)(dirPath);
          childNames.sort();
          const isTopLevel = dirPath === dep.path;
          const dirs = []; // our handler is async, but we should add sorted files, so, we add file to result not in the mapper, but after map

          const sortedFilePaths = yield _bluebirdLst().default.map(childNames, name => {
            if (onNodeModuleFile != null) {
              onNodeModuleFile(dirPath + path.sep + name);
            } // do not exclude *.h files (https://github.com/electron-userland/electron-builder/issues/2852)


            if (excludedFiles.has(name) || name.endsWith(".o") || name.endsWith(".obj") || name.endsWith(".cc") || !isIncludePdb && name.endsWith(".pdb") || name.endsWith(".d.ts") || name.endsWith(".suo") || name.endsWith(".sln") || name.endsWith(".xproj") || name.endsWith(".csproj")) {
              return null;
            } // noinspection SpellCheckingInspection


            if (isTopLevel && (topLevelExcludedFiles.has(name) || dep.name === "libui-node" && (name === "build" || name === "docs" || name === "src"))) {
              return null;
            }

            if (dirPath.endsWith("build")) {
              if (name === "gyp-mac-tool" || name === "Makefile" || name.endsWith(".mk") || name.endsWith(".gypi") || name.endsWith(".Makefile")) {
                return null;
              }
            } else if (dirPath.endsWith("Release") && (name === ".deps" || name === "obj.target")) {
              return null;
            } else if (name === "src" && (dirPath.endsWith("keytar") || dirPath.endsWith("keytar-prebuild"))) {
              return null;
            } else if (dirPath.endsWith("lzma-native") && (name === "build" || name === "deps")) {
              return null;
            }

            const filePath = dirPath + path.sep + name;
            return (0, _fsExtraP().lstat)(filePath).then(stat => {
              if (filter != null && !filter(filePath, stat)) {
                return null;
              }

              if (!stat.isDirectory()) {
                metadata.set(filePath, stat);
              }

              const consumerResult = _this.handleFile(filePath, stat);

              if (consumerResult == null) {
                if (stat.isDirectory()) {
                  dirs.push(name);
                  return null;
                } else {
                  return filePath;
                }
              } else {
                return consumerResult.then(it => {
                  // asarUtil can return modified stat (symlink handling)
                  if ((it == null ? stat : it).isDirectory()) {
                    dirs.push(name);
                    return null;
                  } else {
                    return filePath;
                  }
                });
              }
            });
          }, _fs().CONCURRENCY);

          for (const child of sortedFilePaths) {
            if (child != null) {
              result.push(child);
            }
          }

          dirs.sort();

          for (const child of dirs) {
            queue.push(dirPath + path.sep + child);
          }
        }
      }

      return result;
    })();
  }

} exports.NodeModuleCopyHelper = NodeModuleCopyHelper;
//# sourceMappingURL=NodeModuleCopyHelper.js.map