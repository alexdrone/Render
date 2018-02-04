import Foundation

@objc final class Generator: NSObject {
  // Default is double space.
  static let indentationToken = "  "

  @objc func run() {
    guard let args = validateCommandLineArguments(), args.count == 2 else { return }
    let destination = args[1]
    let files = search(dir: args[0])
    var data = String()
    for file in files {
      data = readStylesheetData(file: file, result: data)
    }
    do {
      guard let root = try YAMLParser(yaml: data).singleRoot(), root.isMapping else {
        warning("Malformed styleesheet file.")
        return
      }
      rm(file: destination)
      touch(file: destination)
      sleep(1)
      let swiftFile = generate(parseRoot(root))
      try swiftFile.write(toFile: destination, atomically: true, encoding: String.Encoding.utf8)
    } catch {
      warning("Exception thrown while parsing the YAML file.")
      return
    }
  }

  // Generate the stylesheet Swift file.
  private func generate(_ defs: [String: [String]]) -> String {
    let i = Generator.indentationToken
    var s = "import UIKit\nimport RenderNeutrino\npublic struct S {\n"
    for (key, values) in defs {
      let swiftName = key.replacingOccurrences(of: ".", with: "_")
      s += "\(i)public enum \(swiftName): String, UIStylesheetProtocol {\n"
      s += "\(i)\(i)public static let styleIdentifier: String = \"\(key)\"\n"
      s += "\(i)\(i)public static let style: [String] = [\(swiftName).styleIdentifier]\n"
      for value in values {
        s += "\(i)\(i)case \(value)\n"
      }
      s += "\(i)}\n"
    }

    s += "\(i)public struct Modifier {\n"
    for (key, _) in defs {
      let components = key.components(separatedBy: ".")
      guard components.count == 3 else { continue }
      let swiftName = key.replacingOccurrences(of: ".", with: "_")
      s += "\(i)\(i)public static let \(swiftName) = \"\(components[2])\"\n"
    }
    s += "\(i)}\n"
    s += "}"
    return s
  }

  private func validateCommandLineArguments() -> [String]? {
    var args = [String](CommandLine.arguments)
    guard args.count > 1 else {
      print("usage: generate [yaml_stylesheets_directory] [output_destination]")
      return nil
    }
    let destination = args.count > 2 ? args[2] : "\(args[1])/S.generated.swift"
    return [args[1], destination]
  }

  private func readStylesheetData(file: String, result: String) -> String {
    let url = URL(fileURLWithPath: file)
    // Skips other known yaml configuration files.
    let path = url.absoluteString.components(separatedBy: "/").last ?? ""
    guard !path.hasPrefix("."), !path.hasPrefix("_"), let c = try? String(contentsOf: url) else {
      return result
    }
    return c.contains("import") ? "\(c)\(result)" : "\(result)\(c)"
  }

  private func parseRoot(_ root: YAMLNode) -> [String: [String]] {
    var dictionary: [String: [String]] = [:]
    for (key, value) in root.mapping ?? [:] {
      var rules: [String] = []
      // Skips the 'import' rule.
      guard key != "import" else { continue }
      // Definition dictionary.
      guard var defDic = value.mapping, let defKey = key.string else { continue }
      // Append the rule keys to the rules array.
      func appendRules(_ node: YAMLNode?) {
        guard let mapping = node?.mapping else { return }
        for (key, _) in mapping where key != "<<" {
          guard let isk = key.string, !isk.hasPrefix("animator-") else {
            continue
          }
          if !rules.contains(isk) {
            rules.append(isk)
          }
        }
      }
      appendRules(value)
      appendRules(value.mapping?["<<"])
      dictionary[defKey] = rules
    }
    return dictionary
  }
}

// Prints a warning message.
private func warning(_ message: String) {
  print("* warning: \(message)")
}

// Searches for all of the *.yml or *.yaml files in the current directory.
private func search(dir: String) -> [String] {
  return search(dir: dir, ext: "yaml") + search(dir: dir, ext: "yml")
}

private func rm(file: String) {
  let task = Process()
  task.launchPath = "/bin/rm"
  task.arguments = [file]
  let pipe = Pipe()
  task.standardOutput = pipe;
  task.launch()
}

private func touch(file: String) {
  let task = Process()
  task.launchPath = "/usr/bin/touch"
  task.arguments = [file]
  let pipe = Pipe()
  task.standardOutput = pipe;
  task.launch()
}

private func search(dir: String, ext: String) -> [String] {
  let task = Process()
  task.launchPath = "/usr/bin/find"
  task.arguments = ["\(dir)", "\"*.\(ext)\""]
  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = nil
  task.launch()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output: String = String(data: data, encoding: String.Encoding.utf8)!
  let files = output.components(separatedBy: "\n").filter() {
    return $0.hasSuffix(".\(ext)")
  }
  return files
}
