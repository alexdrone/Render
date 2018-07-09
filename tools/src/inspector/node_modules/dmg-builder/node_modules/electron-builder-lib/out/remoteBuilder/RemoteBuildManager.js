"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getConnectOptions = getConnectOptions;
exports.checkStatus = checkStatus;
exports.RemoteBuildManager = void 0;

function _bluebirdLst() {
  const data = _interopRequireWildcard(require("bluebird-lst"));

  _bluebirdLst = function () {
    return data;
  };

  return data;
}

function _zipBin() {
  const data = require("7zip-bin");

  _zipBin = function () {
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

function _builderUtilRuntime() {
  const data = require("builder-util-runtime");

  _builderUtilRuntime = function () {
    return data;
  };

  return data;
}

function _child_process() {
  const data = require("child_process");

  _child_process = function () {
    return data;
  };

  return data;
}

function _http() {
  const data = require("http2");

  _http = function () {
    return data;
  };

  return data;
}

var path = _interopRequireWildcard(require("path"));

function _core() {
  const data = require("../core");

  _core = function () {
    return data;
  };

  return data;
}

function _tools() {
  const data = require("../targets/tools");

  _tools = function () {
    return data;
  };

  return data;
}

function _timer() {
  const data = require("../util/timer");

  _timer = function () {
    return data;
  };

  return data;
}

function _remoteBuilderCerts() {
  const data = require("./remote-builder-certs");

  _remoteBuilderCerts = function () {
    return data;
  };

  return data;
}

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

const {
  HTTP2_HEADER_PATH,
  HTTP2_METHOD_POST,
  HTTP2_HEADER_METHOD,
  HTTP2_HEADER_CONTENT_TYPE,
  HTTP2_HEADER_STATUS,
  HTTP_STATUS_OK
} = _http().constants;

const isUseLocalCert = (0, _builderUtil().isEnvTrue)(process.env.USE_ELECTRON_BUILD_SERVICE_LOCAL_CA);

function getConnectOptions() {
  const options = {};
  const caCert = process.env.ELECTRON_BUILD_SERVICE_CA_CERT;

  if (caCert !== "false") {
    if (isUseLocalCert) {
      _builderUtil().log.debug(null, "local certificate authority is used");
    }

    options.ca = caCert || (isUseLocalCert ? _remoteBuilderCerts().ELECTRON_BUILD_SERVICE_LOCAL_CA_CERT : _remoteBuilderCerts().ELECTRON_BUILD_SERVICE_CA_CERT); // we cannot issue cert per IP because build agent can be started on demand (and for security reasons certificate authority is offline).
    // Since own certificate authority is used, it is ok to skip server name verification.

    options.checkServerIdentity = () => undefined;
  }

  return options;
}

class RemoteBuildManager {
  constructor(buildServiceEndpoint, projectInfoManager, unpackedDirectory, outDir, packager) {
    this.buildServiceEndpoint = buildServiceEndpoint;
    this.projectInfoManager = projectInfoManager;
    this.unpackedDirectory = unpackedDirectory;
    this.outDir = outDir;
    this.packager = packager;

    _builderUtil().log.debug({
      endpoint: buildServiceEndpoint
    }, "connect to remote build service");

    this.client = (0, _http().connect)(buildServiceEndpoint, getConnectOptions());
  }

  build(customHeaders) {
    return new (_bluebirdLst().default)((resolve, reject) => {
      const client = this.client;
      client.on("socketError", reject);
      client.on("error", reject);
      let handled = false;
      client.once("close", () => {
        if (!handled) {
          reject(new Error("Closed unexpectedly"));
        }
      });
      client.once("timeout", () => {
        reject(new Error("Timeout"));
      });
      this.doBuild(customHeaders).then(result => {
        handled = true;

        if (result.files != null) {
          for (const artifact of result.files) {
            const localFile = path.join(this.outDir, artifact.file);
            const artifactCreatedEvent = this.artifactInfoToArtifactCreatedEvent(artifact, localFile); // PublishManager uses outDir and options, real (the same as for local build) values must be used

            this.projectInfoManager.packager.dispatchArtifactCreated(artifactCreatedEvent);
          }
        }

        resolve(result);
      }).catch(reject);
    }).finally(() => {
      this.client.destroy();
    });
  }

  doBuild(customHeaders) {
    const StreamJsonObjects = require("stream-json/utils/StreamJsonObjects");

    return new (_bluebirdLst().default)((resolve, reject) => {
      const zstdCompressionLevel = getZstdCompressionLevel(this.buildServiceEndpoint);
      const stream = this.client.request(Object.assign({
        [HTTP2_HEADER_PATH]: "/v2/build",
        [HTTP2_HEADER_METHOD]: HTTP2_METHOD_POST,
        [HTTP2_HEADER_CONTENT_TYPE]: "application/octet-stream"
      }, customHeaders, {
        // only for stats purpose, not required for build
        "x-zstd-compression-level": zstdCompressionLevel
      }));
      stream.on("error", reject); // this.handleStreamEvent(resolve, reject)

      this.uploadUnpackedAppArchive(stream, zstdCompressionLevel, reject);
      stream.on("response", headers => {
        const status = headers[HTTP2_HEADER_STATUS];

        if (status !== HTTP_STATUS_OK) {
          reject(new (_builderUtilRuntime().HttpError)(status));
          return;
        }

        const objectStream = StreamJsonObjects.make();
        objectStream.output.on("data", object => {
          const data = object.value;

          if (_builderUtil().log.isDebugEnabled) {
            _builderUtil().log.debug({
              event: JSON.stringify(data, null, 2)
            }, "remote builder event");
          }

          if (data.status != null) {
            _builderUtil().log.info({
              status: data.status
            }, "remote building");
          } else if ("error" in data) {
            resolve({
              files: null,
              error: data.error
            });
          } else if ("files" in data) {
            this.downloadArtifacts(data.files, data.fileSizes, data.baseUrl).then(() => {
              stream.destroy();
              resolve({
                files: data.files,
                error: null
              });
            }).catch(reject);
          } else {
            _builderUtil().log.warn(`Unknown builder event: ${JSON.stringify(data)}`);
          }
        });
        stream.pipe(objectStream.input);
      });
    });
  }

  downloadArtifacts(files, fileSizes, baseUrl) {
    const args = ["download-resolved-files", "--out", this.outDir, "--base-url", this.buildServiceEndpoint + baseUrl];

    for (let i = 0; i < files.length; i++) {
      const artifact = files[i];
      args.push("-f", artifact.file);
      args.push("-s", fileSizes[i].toString());
    }

    return (0, _builderUtil().executeAppBuilder)(args);
  }

  artifactInfoToArtifactCreatedEvent(artifact, localFile) {
    const target = artifact.target; // noinspection SpellCheckingInspection

    return Object.assign({}, artifact, {
      file: localFile,
      target: target == null ? null : new FakeTarget(target, this.outDir, this.packager.config[target]),
      packager: this.packager
    });
  } // compress and upload in the same time, directly to remote without intermediate local file


  uploadUnpackedAppArchive(stream, zstdCompressionLevel, reject) {
    const packager = this.projectInfoManager.packager;
    const buildResourcesDir = packager.buildResourcesDir;

    if (buildResourcesDir === packager.projectDir) {
      reject(new Error(`Build resources dir equals to project dir and so, not sent to remote build agent. It will lead to incorrect results.\nPlease set "directories.buildResources" to separate dir or leave default ("build" directory in the project root)`));
      return;
    }

    Promise.all([this.projectInfoManager.infoFile.value, (0, _tools().getZstd)()]).then(results => {
      const infoFile = results[0];

      _builderUtil().log.info("compressing and uploading to remote builder");

      const compressAndUploadTimer = new (_timer().DevTimer)("compress and upload"); // noinspection SpellCheckingInspection

      const tarProcess = (0, _child_process().spawn)(_zipBin().path7za, ["a", "dummy", "-ttar", "-so", this.unpackedDirectory, infoFile, buildResourcesDir], {
        stdio: ["pipe", "pipe", process.stderr]
      });
      tarProcess.stdout.on("error", reject);
      const zstdProcess = (0, _child_process().spawn)(results[1], [`-${zstdCompressionLevel}`, "--long"], {
        stdio: ["pipe", "pipe", process.stderr]
      });
      zstdProcess.on("error", reject);
      tarProcess.stdout.pipe(zstdProcess.stdin);
      zstdProcess.stdout.pipe(stream);
      zstdProcess.stdout.on("end", () => {
        _builderUtil().log.info({
          time: compressAndUploadTimer.endAndGet()
        }, "uploaded to remote builder");
      });
    }).catch(reject);
  }

}

exports.RemoteBuildManager = RemoteBuildManager;

function getZstdCompressionLevel(endpoint) {
  const result = process.env.ELECTRON_BUILD_SERVICE_ZSTD_COMPRESSION;

  if (result != null) {
    return result;
  } // 18 - 40s
  // 17 - 30s
  // 16 - 20s


  return endpoint.startsWith("https://127.0.0.1:") || endpoint.startsWith("https://localhost:") || endpoint.startsWith("[::1]:") ? "3" : "16";
}

function checkStatus(status, reject) {
  if (status === HTTP_STATUS_OK) {
    return true;
  } else {
    reject(new (_builderUtilRuntime().HttpError)(status));
    return false;
  }
}

class FakeTarget extends _core().Target {
  constructor(name, outDir, options) {
    super(name);
    this.outDir = outDir;
    this.options = options;
  }

  build(appOutDir, arch) {// no build

    return (0, _bluebirdLst().coroutine)(function* () {})();
  }

} 
//# sourceMappingURL=RemoteBuildManager.js.map