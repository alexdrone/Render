"use strict"

function getPath() {
  if (process.env.USE_SYSTEM_APP_BUILDER === "true") {
    return "app-builder"
  }

  const path = require("path")
  if (process.platform === "darwin") {
    return path.join(__dirname, "mac", "app-builder")
  }
  else if (process.platform === "win32") {
    return path.join(__dirname, "win", process.arch, "app-builder.exe")
  }
  else {
    return path.join(__dirname, "linux", process.arch, "app-builder")
  }
}

exports.appBuilderPath = getPath()