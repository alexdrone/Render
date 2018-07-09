"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isSafeGithubName = isSafeGithubName;
exports.normalizeExt = normalizeExt;
exports.resolveFunction = resolveFunction;
exports.chooseNotNull = chooseNotNull;
exports.PlatformPackager = void 0;

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

function _promise() {
  const data = require("builder-util/out/promise");

  _promise = function () {
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

function _lazyVal() {
  const data = require("lazy-val");

  _lazyVal = function () {
    return data;
  };

  return data;
}

var path = _interopRequireWildcard(require("path"));

function _asarFileChecker() {
  const data = require("./asar/asarFileChecker");

  _asarFileChecker = function () {
    return data;
  };

  return data;
}

function _asarUtil() {
  const data = require("./asar/asarUtil");

  _asarUtil = function () {
    return data;
  };

  return data;
}

function _integrity() {
  const data = require("./asar/integrity");

  _integrity = function () {
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

function _fileMatcher() {
  const data = require("./fileMatcher");

  _fileMatcher = function () {
    return data;
  };

  return data;
}

function _fileTransformer() {
  const data = require("./fileTransformer");

  _fileTransformer = function () {
    return data;
  };

  return data;
}

function _Framework() {
  const data = require("./Framework");

  _Framework = function () {
    return data;
  };

  return data;
}

function _appFileCopier() {
  const data = require("./util/appFileCopier");

  _appFileCopier = function () {
    return data;
  };

  return data;
}

function _AppFileCopierHelper() {
  const data = require("./util/AppFileCopierHelper");

  _AppFileCopierHelper = function () {
    return data;
  };

  return data;
}

function _macroExpander() {
  const data = require("./util/macroExpander");

  _macroExpander = function () {
    return data;
  };

  return data;
}

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

class PlatformPackager {
  constructor(info, platform) {
    this.info = info;
    this.platform = platform;
    this._resourceList = new (_lazyVal().Lazy)(() => (0, _promise().orIfFileNotExist)((0, _fsExtraP().readdir)(this.info.buildResourcesDir), []));
    this.platformSpecificBuildOptions = PlatformPackager.normalizePlatformSpecificBuildOptions(this.config[platform.buildConfigurationKey]);
    this.appInfo = this.prepareAppInfo(info.appInfo);
  }

  get packagerOptions() {
    return this.info.options;
  }

  get buildResourcesDir() {
    return this.info.buildResourcesDir;
  }

  get projectDir() {
    return this.info.projectDir;
  }

  get config() {
    return this.info.config;
  }

  get resourceList() {
    return this._resourceList.value;
  }

  get compression() {
    const compression = this.platformSpecificBuildOptions.compression; // explicitly set to null - request to use default value instead of parent (in the config)

    if (compression === null) {
      return "normal";
    }

    return compression || this.config.compression || "normal";
  }

  get debugLogger() {
    return this.info.debugLogger;
  }

  prepareAppInfo(appInfo) {
    return appInfo;
  }

  static normalizePlatformSpecificBuildOptions(options) {
    return options == null ? Object.create(null) : options;
  }

  getCscPassword() {
    const password = this.doGetCscPassword();

    if ((0, _builderUtil().isEmptyOrSpaces)(password)) {
      _builderUtil().log.info({
        reason: "CSC_KEY_PASSWORD is not defined"
      }, "empty password will be used for code signing");

      return "";
    } else {
      return password.trim();
    }
  }

  getCscLink(extraEnvName) {
    // allow to specify as empty string
    const envValue = chooseNotNull(extraEnvName == null ? null : process.env[extraEnvName], process.env.CSC_LINK);
    return chooseNotNull(chooseNotNull(this.info.config.cscLink, this.platformSpecificBuildOptions.cscLink), envValue);
  }

  doGetCscPassword() {
    // allow to specify as empty string
    return chooseNotNull(chooseNotNull(this.info.config.cscKeyPassword, this.platformSpecificBuildOptions.cscKeyPassword), process.env.CSC_KEY_PASSWORD);
  }

  computeAppOutDir(outDir, arch) {
    return this.packagerOptions.prepackaged || path.join(outDir, `${this.platform.buildConfigurationKey}${(0, _builderUtil().getArchSuffix)(arch)}${this.platform === _core().Platform.MAC ? "" : "-unpacked"}`);
  }

  dispatchArtifactCreated(file, target, arch, safeArtifactName) {
    this.info.dispatchArtifactCreated({
      file,
      safeArtifactName,
      target,
      arch,
      packager: this
    });
  }

  pack(outDir, arch, targets, taskManager) {
    var _this = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const appOutDir = _this.computeAppOutDir(outDir, arch);

      yield _this.doPack(outDir, appOutDir, _this.platform.nodeName, arch, _this.platformSpecificBuildOptions, targets);

      _this.packageInDistributableFormat(appOutDir, arch, targets, taskManager);
    })();
  }

  packageInDistributableFormat(appOutDir, arch, targets, taskManager) {
    var _this2 = this;

    if (targets.find(it => !it.isAsyncSupported) == null) {
      PlatformPackager.buildAsyncTargets(targets, taskManager, appOutDir, arch);
      return;
    }

    taskManager.add((0, _bluebirdLst().coroutine)(function* () {
      // BluebirdPromise.map doesn't invoke target.build immediately, but for RemoteTarget it is very critical to call build() before finishBuild()
      const subTaskManager = new (_builderUtil().AsyncTaskManager)(_this2.info.cancellationToken);
      PlatformPackager.buildAsyncTargets(targets, subTaskManager, appOutDir, arch);
      yield subTaskManager.awaitTasks();

      for (const target of targets) {
        if (!target.isAsyncSupported) {
          yield target.build(appOutDir, arch);
        }
      }
    }));
  }

  static buildAsyncTargets(targets, taskManager, appOutDir, arch) {
    for (const target of targets) {
      if (target.isAsyncSupported) {
        taskManager.addTask(target.build(appOutDir, arch));
      }
    }
  }

  getExtraFileMatchers(isResources, appOutDir, options) {
    const base = isResources ? this.getResourcesDir(appOutDir) : this.platform === _core().Platform.MAC ? path.join(appOutDir, `${this.appInfo.productFilename}.app`, "Contents") : appOutDir;
    return (0, _fileMatcher().getFileMatchers)(this.config, isResources ? "extraResources" : "extraFiles", this.projectDir, base, options);
  }

  get electronDistExecutableName() {
    return this.config.muonVersion == null ? "electron" : "brave";
  }

  get electronDistMacOsExecutableName() {
    return this.config.muonVersion == null ? "Electron" : "Brave";
  }

  doPack(outDir, appOutDir, platformName, arch, platformSpecificBuildOptions, targets) {
    var _this3 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      if (_this3.packagerOptions.prepackaged != null) {
        return;
      }

      const macroExpander = it => _this3.expandMacro(it, arch == null ? null : _builderUtil().Arch[arch], {
        "/*": "{,/**/*}"
      });

      const framework = _this3.info.framework;

      _builderUtil().log.info({
        platform: platformName,
        arch: _builderUtil().Arch[arch],
        [`${framework.name}`]: framework.version,
        appOutDir: _builderUtil().log.filePath(appOutDir)
      }, `packaging`);

      yield framework.prepareApplicationStageDirectory({
        packager: _this3,
        appOutDir,
        platformName,
        arch: _builderUtil().Arch[arch],
        version: framework.version
      });
      const excludePatterns = [];

      const computeParsedPatterns = patterns => {
        if (patterns != null) {
          for (const pattern of patterns) {
            pattern.computeParsedPatterns(excludePatterns, _this3.info.projectDir);
          }
        }
      };

      const getFileMatchersOptions = {
        macroExpander,
        customBuildOptions: platformSpecificBuildOptions,
        outDir
      };

      const extraResourceMatchers = _this3.getExtraFileMatchers(true, appOutDir, getFileMatchersOptions);

      computeParsedPatterns(extraResourceMatchers);

      const extraFileMatchers = _this3.getExtraFileMatchers(false, appOutDir, getFileMatchersOptions);

      computeParsedPatterns(extraFileMatchers);
      const packContext = {
        appOutDir,
        outDir,
        arch,
        targets,
        packager: _this3,
        electronPlatformName: platformName
      };
      const taskManager = new (_builderUtil().AsyncTaskManager)(_this3.info.cancellationToken);
      const asarOptions = yield _this3.computeAsarOptions(platformSpecificBuildOptions);
      const resourcesPath = _this3.platform === _core().Platform.MAC ? path.join(appOutDir, framework.distMacOsAppName, "Contents", "Resources") : (0, _Framework().isElectronBased)(framework) ? path.join(appOutDir, "resources") : appOutDir;

      _this3.copyAppFiles(taskManager, asarOptions, resourcesPath, path.join(resourcesPath, "app"), outDir, platformSpecificBuildOptions, excludePatterns, macroExpander);

      yield taskManager.awaitTasks();

      if (_this3.info.cancellationToken.cancelled) {
        return;
      }

      const beforeCopyExtraFiles = _this3.info.framework.beforeCopyExtraFiles;

      if (beforeCopyExtraFiles != null) {
        yield beforeCopyExtraFiles(_this3, appOutDir, asarOptions == null ? null : yield (0, _integrity().computeData)(resourcesPath, asarOptions.externalAllowed ? {
          externalAllowed: true
        } : null));
      }

      yield _bluebirdLst().default.each([extraResourceMatchers, extraFileMatchers], it => (0, _fileMatcher().copyFiles)(it));

      if (_this3.info.cancellationToken.cancelled) {
        return;
      }

      yield _this3.info.afterPack(packContext);
      yield _this3.sanityCheckPackage(appOutDir, asarOptions != null);
      yield _this3.signApp(packContext);
      yield _this3.info.afterSign(packContext);
    })();
  }

  copyAppFiles(taskManager, asarOptions, resourcePath, defaultDestination, outDir, platformSpecificBuildOptions, excludePatterns, macroExpander) {
    const appDir = this.info.appDir;
    const config = this.config;
    const isElectronCompile = asarOptions != null && (0, _fileTransformer().isElectronCompileUsed)(this.info);
    const mainMatchers = (0, _fileMatcher().getMainFileMatchers)(appDir, defaultDestination, macroExpander, platformSpecificBuildOptions, this, outDir, isElectronCompile);

    if (excludePatterns.length > 0) {
      for (const matcher of mainMatchers) {
        matcher.excludePatterns = excludePatterns;
      }
    }

    const framework = this.info.framework;
    const transformer = (0, _fileTransformer().createTransformer)(appDir, config, isElectronCompile ? Object.assign({
      originalMain: this.info.metadata.main,
      main: _AppFileCopierHelper().ELECTRON_COMPILE_SHIM_FILENAME
    }, config.extraMetadata) : config.extraMetadata, framework.createTransformer == null ? null : framework.createTransformer());

    const _computeFileSets = matchers => {
      return (0, _AppFileCopierHelper().computeFileSets)(matchers, this.info.isPrepackedAppAsar || asarOptions == null ? null : transformer, this.info, isElectronCompile).then(it => it.filter(it => it.files.length > 0));
    };

    if (this.info.isPrepackedAppAsar) {
      taskManager.addTask(_bluebirdLst().default.each(_computeFileSets([new (_fileMatcher().FileMatcher)(appDir, resourcePath, macroExpander)]), it => (0, _appFileCopier().copyAppFiles)(it, this.info, transformer)));
    } else if (asarOptions == null) {
      taskManager.addTask(_bluebirdLst().default.each(_computeFileSets(mainMatchers), it => (0, _appFileCopier().copyAppFiles)(it, this.info, transformer)));
    } else {
      const unpackPattern = (0, _fileMatcher().getFileMatchers)(config, "asarUnpack", appDir, defaultDestination, {
        macroExpander,
        customBuildOptions: platformSpecificBuildOptions,
        outDir
      });
      const fileMatcher = unpackPattern == null ? null : unpackPattern[0];
      taskManager.addTask(_computeFileSets(mainMatchers).then(fileSets => new (_asarUtil().AsarPackager)(appDir, resourcePath, asarOptions, fileMatcher == null ? null : fileMatcher.createFilter()).pack(fileSets, this)));
    }
  }

  signApp(packContext) {
    return Promise.resolve();
  }

  getIconPath() {
    return (0, _bluebirdLst().coroutine)(function* () {
      return null;
    })();
  }

  computeAsarOptions(customBuildOptions) {
    var _this4 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      if (!(0, _Framework().isElectronBased)(_this4.info.framework)) {
        return null;
      }

      function errorMessage(name) {
        return `${name} is deprecated is deprecated and not supported — please use asarUnpack`;
      }

      const buildMetadata = _this4.config;

      if (buildMetadata["asar-unpack"] != null) {
        throw new Error(errorMessage("asar-unpack"));
      }

      if (buildMetadata["asar-unpack-dir"] != null) {
        throw new Error(errorMessage("asar-unpack-dir"));
      }

      const platformSpecific = customBuildOptions.asar;
      const result = platformSpecific == null ? _this4.config.asar : platformSpecific;

      if (result === false) {
        const appAsarStat = yield (0, _fs().statOrNull)(path.join(_this4.info.appDir, "app.asar")); //noinspection ES6MissingAwait

        if (appAsarStat == null || !appAsarStat.isFile()) {
          _builderUtil().log.warn({
            solution: "enable asar and use asarUnpack to unpack files that must be externally available"
          }, "asar using is disabled — it is strongly not recommended");
        }

        return null;
      }

      if (result == null || result === true) {
        return {};
      }

      for (const name of ["unpackDir", "unpack"]) {
        if (result[name] != null) {
          throw new Error(errorMessage(`asar.${name}`));
        }
      }

      return (0, _builderUtil().deepAssign)({}, result);
    })();
  }

  getElectronSrcDir(dist) {
    return path.resolve(this.projectDir, dist);
  }

  getElectronDestinationDir(appOutDir) {
    return appOutDir;
  }

  getResourcesDir(appOutDir) {
    if (this.platform === _core().Platform.MAC) {
      return this.getMacOsResourcesDir(appOutDir);
    } else if ((0, _Framework().isElectronBased)(this.info.framework)) {
      return path.join(appOutDir, "resources");
    } else {
      return appOutDir;
    }
  }

  getMacOsResourcesDir(appOutDir) {
    return path.join(appOutDir, `${this.appInfo.productFilename}.app`, "Contents", "Resources");
  }

  checkFileInPackage(resourcesDir, file, messagePrefix, isAsar) {
    var _this5 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const relativeFile = path.relative(_this5.info.appDir, path.resolve(_this5.info.appDir, file));

      if (isAsar) {
        yield (0, _asarFileChecker().checkFileInArchive)(path.join(resourcesDir, "app.asar"), relativeFile, messagePrefix);
        return;
      }

      const pathParsed = path.parse(file); // Even when packaging to asar is disabled, it does not imply that the main file can not be inside an .asar archive.
      // This may occur when the packaging is done manually before processing with electron-builder.

      if (pathParsed.dir.includes(".asar")) {
        // The path needs to be split to the part with an asar archive which acts like a directory and the part with
        // the path to main file itself. (e.g. path/arch.asar/dir/index.js -> path/arch.asar, dir/index.js)
        // noinspection TypeScriptValidateJSTypes
        const pathSplit = pathParsed.dir.split(path.sep);
        let partWithAsarIndex = 0;
        pathSplit.some((pathPart, index) => {
          partWithAsarIndex = index;
          return pathPart.endsWith(".asar");
        });
        const asarPath = path.join.apply(path, pathSplit.slice(0, partWithAsarIndex + 1));
        let mainPath = pathSplit.length > partWithAsarIndex + 1 ? path.join.apply(pathSplit.slice(partWithAsarIndex + 1)) : "";
        mainPath += path.join(mainPath, pathParsed.base);
        yield (0, _asarFileChecker().checkFileInArchive)(path.join(resourcesDir, "app", asarPath), mainPath, messagePrefix);
      } else {
        const outStat = yield (0, _fs().statOrNull)(path.join(resourcesDir, "app", relativeFile));

        if (outStat == null) {
          throw new Error(`${messagePrefix} "${relativeFile}" does not exist. Seems like a wrong configuration.`);
        } else {
          //noinspection ES6MissingAwait
          if (!outStat.isFile()) {
            throw new Error(`${messagePrefix} "${relativeFile}" is not a file. Seems like a wrong configuration.`);
          }
        }
      }
    })();
  }

  sanityCheckPackage(appOutDir, isAsar) {
    var _this6 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const outStat = yield (0, _fs().statOrNull)(appOutDir);

      if (outStat == null) {
        throw new Error(`Output directory "${appOutDir}" does not exist. Seems like a wrong configuration.`);
      } else {
        //noinspection ES6MissingAwait
        if (!outStat.isDirectory()) {
          throw new Error(`Output directory "${appOutDir}" is not a directory. Seems like a wrong configuration.`);
        }
      }

      const resourcesDir = _this6.getResourcesDir(appOutDir);

      yield _this6.checkFileInPackage(resourcesDir, _this6.info.metadata.main || "index.js", "Application entry file", isAsar);
      yield _this6.checkFileInPackage(resourcesDir, "package.json", "Application", isAsar);
    })();
  }

  computeSafeArtifactName(suggestedName, ext, arch, skipArchIfX64 = true) {
    // GitHub only allows the listed characters in file names.
    if (suggestedName != null && isSafeGithubName(suggestedName)) {
      return null;
    } // tslint:disable-next-line:no-invalid-template-strings


    return this.computeArtifactName("${name}-${version}-${arch}.${ext}", ext, skipArchIfX64 && arch === _builderUtil().Arch.x64 ? null : arch);
  }

  expandArtifactNamePattern(targetSpecificOptions, ext, arch, defaultPattern, skipArchIfX64 = true) {
    let pattern = targetSpecificOptions == null ? null : targetSpecificOptions.artifactName;

    if (pattern == null) {
      // tslint:disable-next-line:no-invalid-template-strings
      pattern = this.platformSpecificBuildOptions.artifactName || this.config.artifactName || defaultPattern || "${productName}-${version}-${arch}.${ext}";
    }

    return this.computeArtifactName(pattern, ext, skipArchIfX64 && arch === _builderUtil().Arch.x64 ? null : arch);
  }

  computeArtifactName(pattern, ext, arch) {
    let archName = arch == null ? null : _builderUtil().Arch[arch];

    if (arch === _builderUtil().Arch.x64) {
      if (ext === "AppImage" || ext === "rpm") {
        archName = "x86_64";
      } else if (ext === "deb" || ext === "snap") {
        archName = "amd64";
      }
    } else if (arch === _builderUtil().Arch.ia32) {
      if (ext === "deb" || ext === "AppImage" || ext === "snap") {
        archName = "i386";
      } else if (ext === "pacman" || ext === "rpm") {
        archName = "i686";
      }
    }

    return this.expandMacro(pattern, this.platform === _core().Platform.MAC ? null : archName, {
      ext
    });
  }

  expandMacro(pattern, arch, extra = {}, isProductNameSanitized = true) {
    return (0, _macroExpander().expandMacro)(pattern, arch, this.appInfo, Object.assign({
      os: this.platform.buildConfigurationKey
    }, extra), isProductNameSanitized);
  }

  generateName(ext, arch, deployment, classifier = null) {
    let c = null;
    let e = null;

    if (arch === _builderUtil().Arch.x64) {
      if (ext === "AppImage") {
        c = "x86_64";
      } else if (ext === "deb") {
        c = "amd64";
      }
    } else if (arch === _builderUtil().Arch.ia32 && ext === "deb") {
      c = "i386";
    } else if (ext === "pacman") {
      if (arch === _builderUtil().Arch.ia32) {
        c = "i686";
      }

      e = "pkg.tar.xz";
    } else {
      c = _builderUtil().Arch[arch];
    }

    if (c == null) {
      c = classifier;
    } else if (classifier != null) {
      c += `-${classifier}`;
    }

    if (e == null) {
      e = ext;
    }

    return this.generateName2(e, c, deployment);
  }

  generateName2(ext, classifier, deployment) {
    const dotExt = ext == null ? "" : `.${ext}`;
    const separator = ext === "deb" ? "_" : "-";
    return `${deployment ? this.appInfo.name : this.appInfo.productFilename}${separator}${this.appInfo.version}${classifier == null ? "" : `${separator}${classifier}`}${dotExt}`;
  }

  getTempFile(suffix) {
    return this.info.tempDirManager.getTempFile({
      suffix
    });
  }

  get fileAssociations() {
    return (0, _builderUtil().asArray)(this.config.fileAssociations).concat((0, _builderUtil().asArray)(this.platformSpecificBuildOptions.fileAssociations));
  }

  getResource(custom, ...names) {
    var _this7 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const resourcesDir = _this7.info.buildResourcesDir;

      if (custom === undefined) {
        const resourceList = yield _this7.resourceList;

        for (const name of names) {
          if (resourceList.includes(name)) {
            return path.join(resourcesDir, name);
          }
        }
      } else if (custom != null && !(0, _builderUtil().isEmptyOrSpaces)(custom)) {
        const resourceList = yield _this7.resourceList;

        if (resourceList.includes(custom)) {
          return path.join(resourcesDir, custom);
        }

        let p = path.resolve(resourcesDir, custom);

        if ((yield (0, _fs().statOrNull)(p)) == null) {
          p = path.resolve(_this7.projectDir, custom);

          if ((yield (0, _fs().statOrNull)(p)) == null) {
            throw new (_builderUtil().InvalidConfigurationError)(`cannot find specified resource "${custom}", nor relative to "${resourcesDir}", neither relative to project dir ("${_this7.projectDir}")`);
          }
        }

        return p;
      }

      return null;
    })();
  }

  get forceCodeSigning() {
    const forceCodeSigningPlatform = this.platformSpecificBuildOptions.forceCodeSigning;
    return (forceCodeSigningPlatform == null ? this.config.forceCodeSigning : forceCodeSigningPlatform) || false;
  }

  getOrConvertIcon(format) {
    var _this8 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const sourceNames = [`icon.${format === "set" ? "png" : format}`, "icon.png", "icons"];
      const iconPath = _this8.platformSpecificBuildOptions.icon || _this8.config.icon;

      if (iconPath != null) {
        sourceNames.unshift(iconPath);
      }

      if (format === "ico") {
        sourceNames.push("icon.icns");
      }

      const result = yield _this8.resolveIcon(sourceNames, format);

      if (result.length === 0) {
        const framework = _this8.info.framework;

        if (framework.getDefaultIcon != null) {
          return framework.getDefaultIcon(_this8.platform);
        }

        _builderUtil().log.warn({
          reason: "application icon is not set"
        }, framework.isDefaultAppIconProvided ? `default ${capitalizeFirstLetter(framework.name)} icon is used` : `application doesn't have an icon`);

        return null;
      } else {
        return result[0].file;
      }
    })();
  } // convert if need, validate size (it is a reason why tool is called even if file has target extension (already specified as foo.icns for example))


  resolveIcon(sources, outputFormat) {
    var _this9 = this;

    return (0, _bluebirdLst().coroutine)(function* () {
      const args = ["icon", "--format", outputFormat, "--root", _this9.buildResourcesDir, "--root", _this9.projectDir, "--out", path.resolve(_this9.projectDir, _this9.config.directories.output, `.icon-${outputFormat}`)];

      for (const source of sources) {
        args.push("--input", source);
      }

      const rawResult = yield (0, _builderUtil().executeAppBuilder)(args);
      let result;

      try {
        result = JSON.parse(rawResult);
      } catch (e) {
        throw new Error(`Cannot parse result: ${e.message}: ${rawResult}`);
      }

      const errorMessage = result.error;

      if (errorMessage != null) {
        throw new (_builderUtil().InvalidConfigurationError)(errorMessage, result.errorCode);
      }

      return result.icons || [];
    })();
  }

}

exports.PlatformPackager = PlatformPackager;

function isSafeGithubName(name) {
  return /^[0-9A-Za-z._-]+$/.test(name);
} // remove leading dot


function normalizeExt(ext) {
  return ext.startsWith(".") ? ext.substring(1) : ext;
}

function resolveFunction(executor) {
  if (executor == null || typeof executor !== "string") {
    return executor;
  }

  let p = executor;

  if (p.startsWith(".")) {
    p = path.resolve(p);
  }

  try {
    p = require.resolve(p);
  } catch (e) {
    (0, _builderUtil().debug)(e);
    p = path.resolve(p);
  }

  const m = require(p);

  return m.default || m;
}

function chooseNotNull(v1, v2) {
  return v1 == null ? v2 : v1;
}

function capitalizeFirstLetter(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
} 
//# sourceMappingURL=platformPackager.js.map