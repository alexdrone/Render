// Forked from httpswift/swifter.
// See LICENSE file for details.

#if targetEnvironment(simulator)
import Foundation
import Dispatch

class Errno {
  class func description() -> String {
    return String(cString: UnsafePointer(strerror(errno)))
  }
}

func shareFile(_ path: String) -> ((HttpRequest) -> HttpResponse) {
  return { r in
    if let file = try? path.openForReading() {
      return .raw(200, "OK", [:], { writer in
        try? writer.write(file)
        file.close()
      })
    }
    return .notFound
  }
}

func shareFilesFromDirectory(_ directoryPath: String,
                             defaults: [String] = []) -> ((HttpRequest) -> HttpResponse) {
  return { r in
    guard let fileRelativePath = r.params.first else {
      return .notFound
    }
    if fileRelativePath.value.isEmpty {
      for path in defaults {
        if let file = try? (directoryPath + String.pathSeparator + path).openForReading() {
          return .raw(200, "OK", [:], { writer in
            try? writer.write(file)
            file.close()
          })
        }
      }
    }
    if let file =
      try? (directoryPath + String.pathSeparator + fileRelativePath.value).openForReading() {
      return .raw(200, "OK", [:], { writer in
        try? writer.write(file)
        file.close()
      })
    }
    return .notFound
  }
}

func directoryBrowser(_ dir: String) -> ((HttpRequest) -> HttpResponse) {
  return { r in
    guard let (_, value) = r.params.first else {
      return HttpResponse.notFound
    }
    let filePath = dir + String.pathSeparator + value
    do {
      guard try filePath.exists() else {
        return .notFound
      }
      if try filePath.directory() {
        let _ = try filePath.files()
        return scopes {
          html { }
          }(r)
      } else {
        guard let file = try? filePath.openForReading() else {
          return .notFound
        }
        return .raw(200, "OK", [:], { writer in
          try? writer.write(file)
          file.close()
        })
      }
    } catch {
      return HttpResponse.internalServerError
    }
  }
}

enum HttpParserError: Error {
  case InvalidStatusLine(String)
}

class HttpParser {
  init() { }
  func readHttpRequest(_ socket: Socket) throws -> HttpRequest {
    let statusLine = try socket.readLine()
    let statusLineTokens = statusLine.components(separatedBy: " ")
    if statusLineTokens.count < 3 {
      throw HttpParserError.InvalidStatusLine(statusLine)
    }
    let request = HttpRequest()
    request.method = statusLineTokens[0]
    request.path = statusLineTokens[1]
    request.queryParams = extractQueryParams(request.path)
    request.headers = try readHeaders(socket)
    if let contentLength = request.headers["content-length"],
       let contentLengthValue = Int(contentLength) {
      request.body = try readBody(socket, size: contentLengthValue)
    }
    return request
  }

  private func extractQueryParams(_ url: String) -> [(String, String)] {
    guard let questionMark = url.index(of: "?") else {
      return []
    }
    let queryStart = url.index(after: questionMark)
    guard url.endIndex > queryStart else {
      return []
    }
    let query = String(url[queryStart..<url.endIndex])
    return query.components(separatedBy: "&")
      .reduce([(String, String)]()) { (c, s) -> [(String, String)] in
        guard let nameEndIndex = s.index(of: "=") else {
          return c
        }
        guard let name = String(
          s[s.startIndex..<nameEndIndex]).removingPercentEncoding else {
          return c
        }
        let valueStartIndex = s.index(nameEndIndex, offsetBy: 1)
        guard valueStartIndex < s.endIndex else {
          return c + [(name, "")]
        }
        guard let value = String(
          s[valueStartIndex..<s.endIndex]).removingPercentEncoding else {
          return c + [(name, "")]
        }
        return c + [(name, value)]
    }
  }

  private func readBody(_ socket: Socket, size: Int) throws -> [UInt8] {
    var body = [UInt8]()
    for _ in 0..<size { body.append(try socket.read()) }
    return body
  }

  private func readHeaders(_ socket: Socket) throws -> [String: String] {
    var headers = [String: String]()
    while case let headerLine = try socket.readLine() , !headerLine.isEmpty {
      let headerTokens = headerLine.components(separatedBy: ":")
      if let name = headerTokens.first, let value = headerTokens.last {
        headers[name.lowercased()] = value.trimmingCharacters(in: .whitespaces)
      }
    }
    return headers
  }

  func supportsKeepAlive(_ headers: [String: String]) -> Bool {
    if let value = headers["connection"] {
      return "keep-alive" == value.trimmingCharacters(in: .whitespaces)
    }
    return false
  }
}

class HttpRequest {
  var path: String = ""
  var queryParams: [(String, String)] = []
  var method: String = ""
  var headers: [String: String] = [:]
  var body: [UInt8] = []
  var address: String? = ""
  var params: [String: String] = [:]

  init() {}

  func hasTokenForHeader(_ headerName: String, token: String) -> Bool {
    guard let headerValue = headers[headerName] else {
      return false
    }
    return headerValue.components(separatedBy: ",").filter({
      $0.trimmingCharacters(in: .whitespaces).lowercased() == token }).count > 0
  }

  func parseUrlencodedForm() -> [(String, String)] {
    guard let contentTypeHeader = headers["content-type"] else {
      return []
    }
    let contentTypeHeaderTokens = contentTypeHeader.components(separatedBy: ";")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    guard let contentType = contentTypeHeaderTokens.first,
              contentType == "application/x-www-form-urlencoded" else {
      return []
    }
    guard let utf8String = String(bytes: body, encoding: .utf8) else {
      // Consider to throw an exception here (examine the encoding from headers).
      return []
    }
    return utf8String.components(separatedBy: "&").map { param -> (String, String) in
      let tokens = param.components(separatedBy: "=")
      if let name = tokens.first?.removingPercentEncoding,
         let value = tokens.last?.removingPercentEncoding, tokens.count == 2 {
        return (name.replacingOccurrences(of: "+", with: " "),
                value.replacingOccurrences(of: "+", with: " "))
      }
      return ("","")
    }
  }

  struct MultiPart {

    let headers: [String: String]
    let body: [UInt8]

    var name: String? {
      return valueFor("content-disposition", parameter: "name")?.unquote()
    }

    var fileName: String? {
      return valueFor("content-disposition", parameter: "filename")?.unquote()
    }

    private func valueFor(_ headerName: String, parameter: String) -> String? {
      return headers.reduce([String]()) {
        (combined, header: (key: String, value: String)) -> [String] in
        guard header.key == headerName else {
          return combined
        }
        let headerValueParams = header.value.components(separatedBy: ";")
          .map { $0.trimmingCharacters(in: .whitespaces) }
        return headerValueParams.reduce(combined, { (results, token) -> [String] in
          let parameterTokens = token.components(separatedBy: "=")
          if parameterTokens.first == parameter, let value = parameterTokens.last {
            return results + [value]
          }
          return results
        })
        }.first
    }
  }

  func parseMultiPartFormData() -> [MultiPart] {
    guard let contentTypeHeader = headers["content-type"] else {
      return []
    }
    let contentTypeHeaderTokens = contentTypeHeader.components(separatedBy: ";").map {
      $0.trimmingCharacters(in: .whitespaces)

    }
    guard let contentType = contentTypeHeaderTokens.first,
              contentType == "multipart/form-data" else {
      return []
    }
    var boundary: String? = nil
    contentTypeHeaderTokens.forEach({
      let tokens = $0.components(separatedBy: "=")
      if let key = tokens.first, key == "boundary" && tokens.count == 2 {
        boundary = tokens.last
      }
    })
    if let boundary = boundary, boundary.utf8.count > 0 {
      return parseMultiPartFormData(body, boundary: "--\(boundary)")
    }
    return []
  }

  private func parseMultiPartFormData(_ data: [UInt8], boundary: String) -> [MultiPart] {
    var generator = data.makeIterator()
    var result = [MultiPart]()
    while let part = nextMultiPart(&generator, boundary: boundary, isFirst: result.isEmpty) {
      result.append(part)
    }
    return result
  }

  private func nextMultiPart(_ generator: inout IndexingIterator<[UInt8]>,
                             boundary: String,
                             isFirst: Bool) -> MultiPart? {
    if isFirst {
      guard nextUTF8MultiPartLine(&generator) == boundary else {
        return nil
      }
    } else {
      let /* ignore */ _ = nextUTF8MultiPartLine(&generator)
    }
    var headers = [String: String]()
    while let line = nextUTF8MultiPartLine(&generator), !line.isEmpty {
      let tokens = line.components(separatedBy: ":")
      if let name = tokens.first, let value = tokens.last, tokens.count == 2 {
        headers[name.lowercased()] = value.trimmingCharacters(in: .whitespaces)
      }
    }
    guard let body = nextMultiPartBody(&generator, boundary: boundary) else {
      return nil
    }
    return MultiPart(headers: headers, body: body)
  }

  private func nextUTF8MultiPartLine(_ generator: inout IndexingIterator<[UInt8]>) -> String? {
    var temp = [UInt8]()
    while let value = generator.next() {
      if value > HttpRequest.CR {
        temp.append(value)
      }
      if value == HttpRequest.NL {
        break
      }
    }
    return String(bytes: temp, encoding: String.Encoding.utf8)
  }

  static let CR = UInt8(13)
  static let NL = UInt8(10)

  private func nextMultiPartBody(_ generator: inout IndexingIterator<[UInt8]>,
                                 boundary: String) -> [UInt8]? {
    var body = [UInt8]()
    let boundaryArray = [UInt8](boundary.utf8)
    var matchOffset = 0;
    while let x = generator.next() {
      matchOffset = ( x == boundaryArray[matchOffset] ? matchOffset + 1 : 0 )
      body.append(x)
      if matchOffset == boundaryArray.count {
        body.removeSubrange(CountableRange<Int>(body.count-matchOffset ..< body.count))
        if body.last == HttpRequest.NL {
          body.removeLast()
          if body.last == HttpRequest.CR {
            body.removeLast()
          }
        }
        return body
      }
    }
    return nil
  }
}

enum SerializationError: Error {
  case invalidObject
  case notSupported
}

protocol HttpResponseBodyWriter {
  func write(_ file: String.File) throws
  func write(_ data: [UInt8]) throws
  func write(_ data: ArraySlice<UInt8>) throws
  func write(_ data: NSData) throws
  func write(_ data: Data) throws
}

enum HttpResponseBody {

  case json(AnyObject)
  case html(String)
  case text(String)
  case xml(String)
  case custom(Any, (Any) throws -> String)

  func content() -> (Int, ((HttpResponseBodyWriter) throws -> Void)?) {
    do {
      switch self {
      case .json(let object):
        #if os(Linux)
          let data = [UInt8]("Not ready for Linux.".utf8)
          return (data.count, {
            try $0.write(data)
          })
        #else
          guard JSONSerialization.isValidJSONObject(object) else {
            throw SerializationError.invalidObject
          }
          let data = try JSONSerialization.data(withJSONObject: object)
          return (data.count, {
            try $0.write(data)
          })
        #endif
      case .text(let body):
        let data = [UInt8](body.utf8)
        return (data.count, {
          try $0.write(data)
        })
      case .xml(let body):
        let data = [UInt8](body.utf8)
        return (data.count, {
          try $0.write(data)
        })
      case .html(let body):
        let serialised = "<html><meta charset=\"UTF-8\"><body>\(body)</body></html>"
        let data = [UInt8](serialised.utf8)
        return (data.count, {
          try $0.write(data)
        })
      case .custom(let object, let closure):
        let serialised = try closure(object)
        let data = [UInt8](serialised.utf8)
        return (data.count, {
          try $0.write(data)
        })
      }
    } catch {
      let data = [UInt8]("Serialisation error: \(error)".utf8)
      return (data.count, {
        try $0.write(data)
      })
    }
  }
}

enum HttpResponse {

  case switchProtocols([String: String], (Socket) -> Void)
  case ok(HttpResponseBody), created, accepted
  case movedPermanently(String)
  case badRequest(HttpResponseBody?), unauthorized, forbidden, notFound
  case internalServerError
  case raw(Int, String, [String:String]?, ((HttpResponseBodyWriter) throws -> Void)? )

  func statusCode() -> Int {
    switch self {
    case .switchProtocols(_, _)   : return 101
    case .ok(_)                   : return 200
    case .created                 : return 201
    case .accepted                : return 202
    case .movedPermanently        : return 301
    case .badRequest(_)           : return 400
    case .unauthorized            : return 401
    case .forbidden               : return 403
    case .notFound                : return 404
    case .internalServerError     : return 500
    case .raw(let code, _ , _, _) : return code
    }
  }

  func reasonPhrase() -> String {
    switch self {
    case .switchProtocols(_, _)    : return "Switching Protocols"
    case .ok(_)                    : return "OK"
    case .created                  : return "Created"
    case .accepted                 : return "Accepted"
    case .movedPermanently         : return "Moved Permanently"
    case .badRequest(_)            : return "Bad Request"
    case .unauthorized             : return "Unauthorized"
    case .forbidden                : return "Forbidden"
    case .notFound                 : return "Not Found"
    case .internalServerError      : return "Internal Server Error"
    case .raw(_, let phrase, _, _) : return phrase
    }
  }

  func headers() -> [String: String] {
    var headers = ["Server" : "Swifter \(HttpServer.VERSION)"]
    switch self {
    case .switchProtocols(let switchHeaders, _):
      for (key, value) in switchHeaders {
        headers[key] = value
      }
    case .ok(let body):
      switch body {
      case .json(_)   : headers["Content-Type"] = "application/json"
      case .xml(_)   : headers["Content-Type"] = "application/xml"
      case .html(_)   : headers["Content-Type"] = "text/html"
      default:break
      }
    case .movedPermanently(let location):
      headers["Location"] = location
    case .raw(_, _, let rawHeaders, _):
      if let rawHeaders = rawHeaders {
        for (k, v) in rawHeaders {
          headers.updateValue(v, forKey: k)
        }
      }
    default:break
    }
    return headers
  }

  func content() -> (length: Int, write: ((HttpResponseBodyWriter) throws -> Void)?) {
    switch self {
    case .ok(let body)             : return body.content()
    case .badRequest(let body)     : return body?.content() ?? (-1, nil)
    case .raw(_, _, _, let writer) : return (-1, writer)
    default                        : return (-1, nil)
    }
  }

  func socketSession() -> ((Socket) -> Void)?  {
    switch self {
    case .switchProtocols(_, let handler) : return handler
    default: return nil
    }
  }
}

func ==(inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
  return inLeft.statusCode() == inRight.statusCode()
}

class HttpRouter {

  init() { }

  private class Node {
    var nodes = [String: Node]()
    var handler: ((HttpRequest) -> HttpResponse)? = nil
  }

  private var rootNode = Node()

  func routes() -> [String] {
    var routes = [String]()
    for (_, child) in rootNode.nodes {
      routes.append(contentsOf: routesForNode(child));
    }
    return routes
  }

  private func routesForNode(_ node: Node, prefix: String = "") -> [String] {
    var result = [String]()
    if let _ = node.handler {
      result.append(prefix)
    }
    for (key, child) in node.nodes {
      result.append(contentsOf: routesForNode(child, prefix: prefix + "/" + key));
    }
    return result
  }

  func register(_ method: String?, path: String, handler: ((HttpRequest) -> HttpResponse)?) {
    var pathSegments = stripQuery(path).split("/")
    if let method = method {
      pathSegments.insert(method, at: 0)
    } else {
      pathSegments.insert("*", at: 0)
    }
    var pathSegmentsGenerator = pathSegments.makeIterator()
    inflate(&rootNode, generator: &pathSegmentsGenerator).handler = handler
  }

  func route(_ method: String?, path: String) ->([String: String], (HttpRequest) -> HttpResponse)? {
    if let method = method {
      let pathSegments = (method + "/" + stripQuery(path)).split("/")
      var pathSegmentsGenerator = pathSegments.makeIterator()
      var params = [String:String]()
      if let handler = findHandler(&rootNode, params: &params, generator: &pathSegmentsGenerator) {
        return (params, handler)
      }
    }
    let pathSegments = ("*/" + stripQuery(path)).split("/")
    var pathSegmentsGenerator = pathSegments.makeIterator()
    var params = [String:String]()
    if let handler = findHandler(&rootNode, params: &params, generator: &pathSegmentsGenerator) {
      return (params, handler)
    }
    return nil
  }

  private func inflate(_ node: inout Node, generator: inout IndexingIterator<[String]>) -> Node {
    if let pathSegment = generator.next() {
      if let _ = node.nodes[pathSegment] {
        return inflate(&node.nodes[pathSegment]!, generator: &generator)
      }
      var nextNode = Node()
      node.nodes[pathSegment] = nextNode
      return inflate(&nextNode, generator: &generator)
    }
    return node
  }

  private func findHandler(_ node: inout Node,
                           params: inout [String: String],
                           generator: inout IndexingIterator<[String]>)
                           -> ((HttpRequest) -> HttpResponse)? {
    guard let pathToken = generator.next() else {
      if let variableNode = node.nodes.filter({ $0.0.first == ":" }).first {
        if variableNode.value.nodes.isEmpty {
          params[variableNode.0] = ""
          return variableNode.value.handler
        }
      }
      return node.handler
    }
    let variableNodes = node.nodes.filter { $0.0.first == ":" }
    if let variableNode = variableNodes.first {
      if variableNode.1.nodes.count == 0 {
        // if it's the last element of the pattern and it's a variable, stop the search and
        // append a tail as a value for the variable.
        let tail = generator.joined(separator: "/")
        if tail.count > 0 {
          params[variableNode.0] = pathToken + "/" + tail
        } else {
          params[variableNode.0] = pathToken
        }
        return variableNode.1.handler
      }
      params[variableNode.0] = pathToken
      return findHandler(&node.nodes[variableNode.0]!, params: &params, generator: &generator)
    }
    if var node = node.nodes[pathToken] {
      return findHandler(&node, params: &params, generator: &generator)
    }
    if var node = node.nodes["*"] {
      return findHandler(&node, params: &params, generator: &generator)
    }
    if let startStarNode = node.nodes["**"] {
      let startStarNodeKeys = startStarNode.nodes.keys
      while let pathToken = generator.next() {
        if startStarNodeKeys.contains(pathToken) {
          return findHandler(&startStarNode.nodes[pathToken]!,
                             params: &params,
                             generator: &generator)
        }
      }
    }
    return nil
  }

  private func stripQuery(_ path: String) -> String {
    if let path = path.components(separatedBy: "?").first {
      return path
    }
    return path
  }
}

extension String {

  func split(_ separator: Character) -> [String] {
    return self.split { $0 == separator }.map(String.init)
  }
}

class HttpServer: HttpServerIO {
  static let VERSION = "1.3.3"
  private let router = HttpRouter()

  override init() {
    self.DELETE = MethodRoute(method: "DELETE", router: router)
    self.UPDATE = MethodRoute(method: "UPDATE", router: router)
    self.HEAD   = MethodRoute(method: "HEAD", router: router)
    self.POST   = MethodRoute(method: "POST", router: router)
    self.GET    = MethodRoute(method: "GET", router: router)
    self.PUT    = MethodRoute(method: "PUT", router: router)
    self.delete = MethodRoute(method: "DELETE", router: router)
    self.update = MethodRoute(method: "UPDATE", router: router)
    self.head   = MethodRoute(method: "HEAD", router: router)
    self.post   = MethodRoute(method: "POST", router: router)
    self.get    = MethodRoute(method: "GET", router: router)
    self.put    = MethodRoute(method: "PUT", router: router)
  }

  var DELETE, UPDATE, HEAD, POST, GET, PUT : MethodRoute
  var delete, update, head, post, get, put : MethodRoute

  subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
    set {
      router.register(nil, path: path, handler: newValue)
    }
    get { return nil }
  }

  var routes: [String] {
    return router.routes();
  }

  var notFoundHandler: ((HttpRequest) -> HttpResponse)?

  var middleware = Array<(HttpRequest) -> HttpResponse?>()

  override func dispatch(_ request: HttpRequest) ->
                        ([String:String], (HttpRequest) -> HttpResponse) {
    for layer in middleware {
      if let response = layer(request) {
        return ([:], { _ in response })
      }
    }
    if let result = router.route(request.method, path: request.path) {
      return result
    }
    if let notFoundHandler = self.notFoundHandler {
      return ([:], notFoundHandler)
    }
    return super.dispatch(request)
  }

  struct MethodRoute {
    let method: String
    let router: HttpRouter
    subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
      set {
        router.register(method, path: path, handler: newValue)
      }
      get { return nil }
    }
  }
}

protocol HttpServerIODelegate: class {
  func socketConnectionReceived(_ socket: Socket)
}

class HttpServerIO {

  weak var delegate : HttpServerIODelegate?

  private var socket = Socket(socketFileDescriptor: -1)
  private var sockets = Set<Socket>()

  enum HttpServerIOState: Int32 {
    case starting
    case running
    case stopping
    case stopped
  }

  private var stateValue: Int32 = HttpServerIOState.stopped.rawValue

  private(set) var state: HttpServerIOState {
    get {
      return HttpServerIOState(rawValue: stateValue)!
    }
    set(state) {
      #if !os(Linux)
        OSAtomicCompareAndSwapInt(self.state.rawValue, state.rawValue, &stateValue)
      #else
        //TODO - hehe :)
        self.stateValue = state.rawValue
      #endif
    }
  }

  var operating: Bool { get { return self.state == .running } }

  /// String representation of the IPv4 address to receive requests from.
  /// It's only used when the server is started with `forceIPv4` option set to true.
  /// Otherwise, `listenAddressIPv6` will be used.
  var listenAddressIPv4: String?

  /// String representation of the IPv6 address to receive requests from.
  /// It's only used when the server is started with `forceIPv4` option set to false.
  /// Otherwise, `listenAddressIPv4` will be used.
  var listenAddressIPv6: String?

  private let queue = DispatchQueue(label: "swifter.httpserverio.clientsockets")

  func port() throws -> Int {
    return Int(try socket.port())
  }

  func isIPv4() throws -> Bool {
    return try socket.isIPv4()
  }

  deinit {
    stop()
  }

  @available(macOS 10.10, *)
  func start(_ port: in_port_t = 8080,
             forceIPv4: Bool = false,
             priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.background) throws {
    guard !self.operating else { return }
    stop()
    self.state = .starting
    let address = forceIPv4 ? listenAddressIPv4 : listenAddressIPv6
    self.socket = try Socket.tcpSocketForListen(port, forceIPv4, SOMAXCONN, address)
    DispatchQueue.global(qos: priority).async { [weak self] in
      guard let strongSelf = self else { return }
      guard strongSelf.operating else { return }
      while let socket = try? strongSelf.socket.acceptClientSocket() {
        DispatchQueue.global(qos: priority).async { [weak self] in
          guard let strongSelf = self else { return }
          guard strongSelf.operating else { return }
          strongSelf.queue.async {
            strongSelf.sockets.insert(socket)
          }
          strongSelf.handleConnection(socket)
          strongSelf.queue.async {
            strongSelf.sockets.remove(socket)
          }
        }
      }
      strongSelf.stop()
    }
    self.state = .running
  }

  func stop() {
    guard self.operating else { return }
    self.state = .stopping
    // Shutdown connected peers because they can live in 'keep-alive' or 'websocket' loops.
    for socket in self.sockets {
      socket.close()
    }
    self.queue.sync {
      self.sockets.removeAll(keepingCapacity: true)
    }
    socket.close()
    self.state = .stopped
  }

  func dispatch(_ request: HttpRequest) -> ([String: String], (HttpRequest) -> HttpResponse) {
    return ([:], { _ in HttpResponse.notFound })
  }

  private func handleConnection(_ socket: Socket) {
    let parser = HttpParser()
    while self.operating, let request = try? parser.readHttpRequest(socket) {
      let request = request
      request.address = try? socket.peername()
      let (params, handler) = self.dispatch(request)
      request.params = params
      let response = handler(request)
      var keepConnection = parser.supportsKeepAlive(request.headers)
      do {
        if self.operating {
          keepConnection = try self.respond(socket, response: response, keepAlive: keepConnection)
        }
      } catch {
        print("Failed to send response: \(error)")
        break
      }
      if let session = response.socketSession() {
        delegate?.socketConnectionReceived(socket)
        session(socket)
        break
      }
      if !keepConnection { break }
    }
    socket.close()
  }

  private struct InnerWriteContext: HttpResponseBodyWriter {

    let socket: Socket

    func write(_ file: String.File) throws {
      try socket.writeFile(file)
    }

    func write(_ data: [UInt8]) throws {
      try write(ArraySlice(data))
    }

    func write(_ data: ArraySlice<UInt8>) throws {
      try socket.writeUInt8(data)
    }

    func write(_ data: NSData) throws {
      try socket.writeData(data)
    }

    func write(_ data: Data) throws {
      try socket.writeData(data)
    }
  }

  private func respond(_ socket: Socket, response: HttpResponse, keepAlive: Bool) throws -> Bool {
    guard self.operating else { return false }
    try socket.writeUTF8("HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
    let content = response.content()
    if content.length >= 0 {
      try socket.writeUTF8("Content-Length: \(content.length)\r\n")
    }
    if keepAlive && content.length != -1 {
      try socket.writeUTF8("Connection: keep-alive\r\n")
    }
    for (name, value) in response.headers() {
      try socket.writeUTF8("\(name): \(value)\r\n")
    }
    try socket.writeUTF8("\r\n")
    if let writeClosure = content.write {
      let jsContext = InnerWriteContext(socket: socket)
      try writeClosure(jsContext)
    }
    return keepAlive && content.length != -1;
  }
}

class Process {
  static var pid: Int {
    return Int(getpid())
  }
  static var tid: UInt64 {
        #if os(Linux)
            return UInt64(pthread_self())
        #else
            var tid: __uint64_t = 0
            pthread_threadid_np(nil, &tid);
            return UInt64(tid)
        #endif
    }
    private static var signalsWatchers = Array<(Int32) -> Void>()
    private static var signalsObserved = false
    static func watchSignals(_ callback: @escaping (Int32) -> Void) {
        if !signalsObserved {
            [SIGTERM, SIGHUP, SIGSTOP, SIGINT].forEach { item in
                signal(item) {
                    signum in Process.signalsWatchers.forEach { $0(signum) }
                }
            }
            signalsObserved = true
        }
        signalsWatchers.append(callback)
    }
}

func scopes(_ scope: @escaping Closure) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        ScopesBuffer[Process.tid] = ""
        scope()
        return .raw(200, "OK", ["Content-Type": "text/html"], {
            try? $0.write([UInt8](("<!DOCTYPE html>"  + (ScopesBuffer[Process.tid] ?? "")).utf8))
        })
    }
}

typealias Closure = () -> Void

var idd: String? = nil
var dir: String? = nil
var rel: String? = nil
var rev: String? = nil
var alt: String? = nil
var forr: String? = nil
var src: String? = nil
var type: String? = nil
var href: String? = nil
var text: String? = nil
var abbr: String? = nil
var size: String? = nil
var face: String? = nil
var char: String? = nil
var cite: String? = nil
var span: String? = nil
var data: String? = nil
var axis: String? = nil
var Name: String? = nil
var name: String? = nil
var code: String? = nil
var link: String? = nil
var lang: String? = nil
var cols: String? = nil
var rows: String? = nil
var ismap: String? = nil
var shape: String? = nil
var style: String? = nil
var alink: String? = nil
var width: String? = nil
var rules: String? = nil
var align: String? = nil
var frame: String? = nil
var vlink: String? = nil
var deferr: String? = nil
var color: String? = nil
var media: String? = nil
var title: String? = nil
var scope: String? = nil
var classs: String? = nil
var value: String? = nil
var clear: String? = nil
var start: String? = nil
var label: String? = nil
var action: String? = nil
var height: String? = nil
var method: String? = nil
var acceptt: String? = nil
var object: String? = nil
var scheme: String? = nil
var coords: String? = nil
var usemap: String? = nil
var onblur: String? = nil
var nohref: String? = nil
var nowrap: String? = nil
var hspace: String? = nil
var border: String? = nil
var valign: String? = nil
var vspace: String? = nil
var onload: String? = nil
var view: String? = nil
var prompt: String? = nil
var onfocus: String? = nil
var enctype: String? = nil
var onclick: String? = nil
var onkeyup: String? = nil
var profile: String? = nil
var version: String? = nil
var onreset: String? = nil
var charset: String? = nil
var standby: String? = nil
var colspan: String? = nil
var charoff: String? = nil
var classid: String? = nil
var compact: String? = nil
var declare: String? = nil
var rowspan: String? = nil
var checked: String? = nil
var archive: String? = nil
var bgcolor: String? = nil
var content: String? = nil
var noshade: String? = nil
var summary: String? = nil
var headers: String? = nil
var onselect: String? = nil
var readonly: String? = nil
var tabindex: String? = nil
var onchange: String? = nil
var noresize: String? = nil
var disabled: String? = nil
var longdesc: String? = nil
var codebase: String? = nil
var language: String? = nil
var datetime: String? = nil
var selected: String? = nil
var hreflang: String? = nil
var onsubmit: String? = nil
var multiple: String? = nil
var onunload: String? = nil
var codetype: String? = nil
var scrolling: String? = nil
var onkeydown: String? = nil
var maxlength: String? = nil
var valuetype: String? = nil
var accesskey: String? = nil
var onmouseup: String? = nil
var autofocus: String? = nil
var onkeypress: String? = nil
var ondblclick: String? = nil
var onmouseout: String? = nil
var httpEquiv: String? = nil
var background: String? = nil
var onmousemove: String? = nil
var onmouseover: String? = nil
var cellpadding: String? = nil
var onmousedown: String? = nil
var frameborder: String? = nil
var marginwidth: String? = nil
var cellspacing: String? = nil
var placeholder: String? = nil
var marginheight: String? = nil
var acceptCharset: String? = nil

var inner: String? = nil

func a(_ c: Closure) { element("a", c) }
func b(_ c: Closure) { element("b", c) }
func i(_ c: Closure) { element("i", c) }
func p(_ c: Closure) { element("p", c) }
func q(_ c: Closure) { element("q", c) }
func s(_ c: Closure) { element("s", c) }
func u(_ c: Closure) { element("u", c) }

func br(_ c: Closure) { element("br", c) }
func dd(_ c: Closure) { element("dd", c) }
func dl(_ c: Closure) { element("dl", c) }
func dt(_ c: Closure) { element("dt", c) }
func em(_ c: Closure) { element("em", c) }
func hr(_ c: Closure) { element("hr", c) }
func li(_ c: Closure) { element("li", c) }
func ol(_ c: Closure) { element("ol", c) }
func rp(_ c: Closure) { element("rp", c) }
func rt(_ c: Closure) { element("rt", c) }
func td(_ c: Closure) { element("td", c) }
func th(_ c: Closure) { element("th", c) }
func tr(_ c: Closure) { element("tr", c) }
func tt(_ c: Closure) { element("tt", c) }
func ul(_ c: Closure) { element("ul", c) }

func ul<T: Sequence>(_ collection: T, _ c: @escaping (T.Iterator.Element) -> Void) {
    element("ul", {
        for item in collection {
            c(item)
        }
    })
}

func h1(_ c: Closure) { element("h1", c) }
func h2(_ c: Closure) { element("h2", c) }
func h3(_ c: Closure) { element("h3", c) }
func h4(_ c: Closure) { element("h4", c) }
func h5(_ c: Closure) { element("h5", c) }
func h6(_ c: Closure) { element("h6", c) }

func bdi(_ c: Closure) { element("bdi", c) }
func bdo(_ c: Closure) { element("bdo", c) }
func big(_ c: Closure) { element("big", c) }
func col(_ c: Closure) { element("col", c) }
func del(_ c: Closure) { element("del", c) }
func dfn(_ c: Closure) { element("dfn", c) }
func dir(_ c: Closure) { element("dir", c) }
func div(_ c: Closure) { element("div", c) }
func img(_ c: Closure) { element("img", c) }
func ins(_ c: Closure) { element("ins", c) }
func kbd(_ c: Closure) { element("kbd", c) }
func map(_ c: Closure) { element("map", c) }
func nav(_ c: Closure) { element("nav", c) }
func pre(_ c: Closure) { element("pre", c) }
func rtc(_ c: Closure) { element("rtc", c) }
func sub(_ c: Closure) { element("sub", c) }
func sup(_ c: Closure) { element("sup", c) }

func varr(_ c: Closure) { element("var", c) }
func wbr(_ c: Closure) { element("wbr", c) }
func xmp(_ c: Closure) { element("xmp", c) }

func abbr(_ c: Closure) { element("abbr", c) }
func area(_ c: Closure) { element("area", c) }
func base(_ c: Closure) { element("base", c) }
func body(_ c: Closure) { element("body", c) }
func cite(_ c: Closure) { element("cite", c) }
func code(_ c: Closure) { element("code", c) }
func data(_ c: Closure) { element("data", c) }
func font(_ c: Closure) { element("font", c) }
func form(_ c: Closure) { element("form", c) }
func head(_ c: Closure) { element("head", c) }
func html(_ c: Closure) { element("html", c) }
func link(_ c: Closure) { element("link", c) }
func main(_ c: Closure) { element("main", c) }
func mark(_ c: Closure) { element("mark", c) }
func menu(_ c: Closure) { element("menu", c) }
func meta(_ c: Closure) { element("meta", c) }
func nobr(_ c: Closure) { element("nobr", c) }
func ruby(_ c: Closure) { element("ruby", c) }
func samp(_ c: Closure) { element("samp", c) }
func span(_ c: Closure) { element("span", c) }
func time(_ c: Closure) { element("time", c) }

func aside(_ c: Closure) { element("aside", c) }
func audio(_ c: Closure) { element("audio", c) }
func blink(_ c: Closure) { element("blink", c) }
func embed(_ c: Closure) { element("embed", c) }
func frame(_ c: Closure) { element("frame", c) }
func image(_ c: Closure) { element("image", c) }
func input(_ c: Closure) { element("input", c) }
func label(_ c: Closure) { element("label", c) }
func meter(_ c: Closure) { element("meter", c) }
func param(_ c: Closure) { element("param", c) }
func small(_ c: Closure) { element("small", c) }
func style(_ c: Closure) { element("style", c) }
func table(_ c: Closure) { element("table", c) }

func table<T: Sequence>(_ collection: T, c: @escaping (T.Iterator.Element) -> Void) {
    element("table", {
        for item in collection {
            c(item)
        }
    })
}

func tbody(_ c: Closure) { element("tbody", c) }

func tbody<T: Sequence>(_ collection: T, c: @escaping (T.Iterator.Element) -> Void) {
    element("tbody", {
        for item in collection {
            c(item)
        }
    })
}

func tfoot(_ c: Closure) { element("tfoot", c) }
func thead(_ c: Closure) { element("thead", c) }
func title(_ c: Closure) { element("title", c) }
func track(_ c: Closure) { element("track", c) }
func video(_ c: Closure) { element("video", c) }

func applet(_ c: Closure) { element("applet", c) }
func button(_ c: Closure) { element("button", c) }
func canvas(_ c: Closure) { element("canvas", c) }
func center(_ c: Closure) { element("center", c) }
func dialog(_ c: Closure) { element("dialog", c) }
func figure(_ c: Closure) { element("figure", c) }
func footer(_ c: Closure) { element("footer", c) }
func header(_ c: Closure) { element("header", c) }
func hgroup(_ c: Closure) { element("hgroup", c) }
func iframe(_ c: Closure) { element("iframe", c) }
func keygen(_ c: Closure) { element("keygen", c) }
func legend(_ c: Closure) { element("legend", c) }
func object(_ c: Closure) { element("object", c) }
func option(_ c: Closure) { element("option", c) }
func output(_ c: Closure) { element("output", c) }
func script(_ c: Closure) { element("script", c) }
func select(_ c: Closure) { element("select", c) }
func shadow(_ c: Closure) { element("shadow", c) }
func source(_ c: Closure) { element("source", c) }
func spacer(_ c: Closure) { element("spacer", c) }
func strike(_ c: Closure) { element("strike", c) }
func strong(_ c: Closure) { element("strong", c) }

func acronym(_ c: Closure) { element("acronym", c) }
func address(_ c: Closure) { element("address", c) }
func article(_ c: Closure) { element("article", c) }
func bgsound(_ c: Closure) { element("bgsound", c) }
func caption(_ c: Closure) { element("caption", c) }
func command(_ c: Closure) { element("command", c) }
func content(_ c: Closure) { element("content", c) }
func details(_ c: Closure) { element("details", c) }
func elementt(_ c: Closure) { element("element", c) }
func isindex(_ c: Closure) { element("isindex", c) }
func listing(_ c: Closure) { element("listing", c) }
func marquee(_ c: Closure) { element("marquee", c) }
func noembed(_ c: Closure) { element("noembed", c) }
func picture(_ c: Closure) { element("picture", c) }
func section(_ c: Closure) { element("section", c) }
func summary(_ c: Closure) { element("summary", c) }

func basefont(_ c: Closure) { element("basefont", c) }
func colgroup(_ c: Closure) { element("colgroup", c) }
func datalist(_ c: Closure) { element("datalist", c) }
func fieldset(_ c: Closure) { element("fieldset", c) }
func frameset(_ c: Closure) { element("frameset", c) }
func menuitem(_ c: Closure) { element("menuitem", c) }
func multicol(_ c: Closure) { element("multicol", c) }
func noframes(_ c: Closure) { element("noframes", c) }
func noscript(_ c: Closure) { element("noscript", c) }
func optgroup(_ c: Closure) { element("optgroup", c) }
func progress(_ c: Closure) { element("progress", c) }
func template(_ c: Closure) { element("template", c) }
func textarea(_ c: Closure) { element("textarea", c) }

func plaintext(_ c: Closure) { element("plaintext", c) }
func javascript(_ c: Closure) { element("script", ["type": "text/javascript"], c) }
func blockquote(_ c: Closure) { element("blockquote", c) }
func figcaption(_ c: Closure) { element("figcaption", c) }

func stylesheet(_ c: Closure) { element("link", ["rel": "stylesheet", "type": "text/css"], c) }

func element(_ node: String, _ c: Closure) { evaluate(node, [:], c) }
func element(_ node: String, _ attrs: [String: String?] = [:], _ c: Closure) {
  evaluate(node, attrs, c)
}

var ScopesBuffer = [UInt64: String]()

private func evaluate(_ node: String, _ attrs: [String: String?] = [:], _ c: Closure) {

    let stackid = idd
    let stackdir = dir
    let stackrel = rel
    let stackrev = rev
    let stackalt = alt
    let stackfor = forr
    let stacksrc = src
    let stacktype = type
    let stackhref = href
    let stacktext = text
    let stackabbr = abbr
    let stacksize = size
    let stackface = face
    let stackchar = char
    let stackcite = cite
    let stackspan = span
    let stackdata = data
    let stackaxis = axis
    let stackName = Name
    let stackname = name
    let stackcode = code
    let stacklink = link
    let stacklang = lang
    let stackcols = cols
    let stackrows = rows
    let stackismap = ismap
    let stackshape = shape
    let stackstyle = style
    let stackalink = alink
    let stackwidth = width
    let stackrules = rules
    let stackalign = align
    let stackframe = frame
    let stackvlink = vlink
    let stackdefer = deferr
    let stackcolor = color
    let stackmedia = media
    let stacktitle = title
    let stackscope = scope
    let stackclass = classs
    let stackvalue = value
    let stackclear = clear
    let stackstart = start
    let stacklabel = label
    let stackaction = action
    let stackheight = height
    let stackmethod = method
    let stackaccept = acceptt
    let stackobject = object
    let stackscheme = scheme
    let stackcoords = coords
    let stackusemap = usemap
    let stackonblur = onblur
    let stacknohref = nohref
    let stacknowrap = nowrap
    let stackhspace = hspace
    let stackborder = border
    let stackvalign = valign
    let stackvspace = vspace
    let stackonload = onload
    let stacktarget = view
    let stackprompt = prompt
    let stackonfocus = onfocus
    let stackenctype = enctype
    let stackonclick = onclick
    let stackonkeyup = onkeyup
    let stackprofile = profile
    let stackversion = version
    let stackonreset = onreset
    let stackcharset = charset
    let stackstandby = standby
    let stackcolspan = colspan
    let stackcharoff = charoff
    let stackclassid = classid
    let stackcompact = compact
    let stackdeclare = declare
    let stackrowspan = rowspan
    let stackchecked = checked
    let stackarchive = archive
    let stackbgcolor = bgcolor
    let stackcontent = content
    let stacknoshade = noshade
    let stacksummary = summary
    let stackheaders = headers
    let stackonselect = onselect
    let stackreadonly = readonly
    let stacktabindex = tabindex
    let stackonchange = onchange
    let stacknoresize = noresize
    let stackdisabled = disabled
    let stacklongdesc = longdesc
    let stackcodebase = codebase
    let stacklanguage = language
    let stackdatetime = datetime
    let stackselected = selected
    let stackhreflang = hreflang
    let stackonsubmit = onsubmit
    let stackmultiple = multiple
    let stackonunload = onunload
    let stackcodetype = codetype
    let stackscrolling = scrolling
    let stackonkeydown = onkeydown
    let stackmaxlength = maxlength
    let stackvaluetype = valuetype
    let stackaccesskey = accesskey
    let stackonmouseup = onmouseup
    let stackonkeypress = onkeypress
    let stackondblclick = ondblclick
    let stackonmouseout = onmouseout
    let stackhttpEquiv = httpEquiv
    let stackbackground = background
    let stackonmousemove = onmousemove
    let stackonmouseover = onmouseover
    let stackcellpadding = cellpadding
    let stackonmousedown = onmousedown
    let stackframeborder = frameborder
    let stackmarginwidth = marginwidth
    let stackcellspacing = cellspacing
    let stackplaceholder = placeholder
    let stackmarginheight = marginheight
    let stackacceptCharset = acceptCharset
    let stackinner = inner

    idd = nil
    dir = nil
    rel = nil
    rev = nil
    alt = nil
    forr = nil
    src = nil
    type = nil
    href = nil
    text = nil
    abbr = nil
    size = nil
    face = nil
    char = nil
    cite = nil
    span = nil
    data = nil
    axis = nil
    Name = nil
    name = nil
    code = nil
    link = nil
    lang = nil
    cols = nil
    rows = nil
    ismap = nil
    shape = nil
    style = nil
    alink = nil
    width = nil
    rules = nil
    align = nil
    frame = nil
    vlink = nil
    deferr = nil
    color = nil
    media = nil
    title = nil
    scope = nil
    classs = nil
    value = nil
    clear = nil
    start = nil
    label = nil
    action = nil
    height = nil
    method = nil
    acceptt = nil
    object = nil
    scheme = nil
    coords = nil
    usemap = nil
    onblur = nil
    nohref = nil
    nowrap = nil
    hspace = nil
    border = nil
    valign = nil
    vspace = nil
    onload = nil
    view = nil
    prompt = nil
    onfocus = nil
    enctype = nil
    onclick = nil
    onkeyup = nil
    profile = nil
    version = nil
    onreset = nil
    charset = nil
    standby = nil
    colspan = nil
    charoff = nil
    classid = nil
    compact = nil
    declare = nil
    rowspan = nil
    checked = nil
    archive = nil
    bgcolor = nil
    content = nil
    noshade = nil
    summary = nil
    headers = nil
    onselect = nil
    readonly = nil
    tabindex = nil
    onchange = nil
    noresize = nil
    disabled = nil
    longdesc = nil
    codebase = nil
    language = nil
    datetime = nil
    selected = nil
    hreflang = nil
    onsubmit = nil
    multiple = nil
    onunload = nil
    codetype = nil
    scrolling = nil
    onkeydown = nil
    maxlength = nil
    valuetype = nil
    accesskey = nil
    onmouseup = nil
    onkeypress = nil
    ondblclick = nil
    onmouseout = nil
    httpEquiv = nil
    background = nil
    onmousemove = nil
    onmouseover = nil
    cellpadding = nil
    onmousedown = nil
    frameborder = nil
    placeholder = nil
    marginwidth = nil
    cellspacing = nil
    marginheight = nil
    acceptCharset = nil
    inner = nil

    ScopesBuffer[Process.tid] = (ScopesBuffer[Process.tid] ?? "") + "<" + node
    var output = ScopesBuffer[Process.tid] ?? ""
    ScopesBuffer[Process.tid] = ""
    c()
    var mergedAttributes = [String: String?]()

    if let idd = idd { mergedAttributes["id"] = idd }
    if let dir = dir { mergedAttributes["dir"] = dir }
    if let rel = rel { mergedAttributes["rel"] = rel }
    if let rev = rev { mergedAttributes["rev"] = rev }
    if let alt = alt { mergedAttributes["alt"] = alt }
    if let forr = forr { mergedAttributes["for"] = forr }
    if let src = src { mergedAttributes["src"] = src }
    if let type = type { mergedAttributes["type"] = type }
    if let href = href { mergedAttributes["href"] = href }
    if let text = text { mergedAttributes["text"] = text }
    if let abbr = abbr { mergedAttributes["abbr"] = abbr }
    if let size = size { mergedAttributes["size"] = size }
    if let face = face { mergedAttributes["face"] = face }
    if let char = char { mergedAttributes["char"] = char }
    if let cite = cite { mergedAttributes["cite"] = cite }
    if let span = span { mergedAttributes["span"] = span }
    if let data = data { mergedAttributes["data"] = data }
    if let axis = axis { mergedAttributes["axis"] = axis }
    if let Name = Name { mergedAttributes["Name"] = Name }
    if let name = name { mergedAttributes["name"] = name }
    if let code = code { mergedAttributes["code"] = code }
    if let link = link { mergedAttributes["link"] = link }
    if let lang = lang { mergedAttributes["lang"] = lang }
    if let cols = cols { mergedAttributes["cols"] = cols }
    if let rows = rows { mergedAttributes["rows"] = rows }
    if let ismap = ismap { mergedAttributes["ismap"] = ismap }
    if let shape = shape { mergedAttributes["shape"] = shape }
    if let style = style { mergedAttributes["style"] = style }
    if let alink = alink { mergedAttributes["alink"] = alink }
    if let width = width { mergedAttributes["width"] = width }
    if let rules = rules { mergedAttributes["rules"] = rules }
    if let align = align { mergedAttributes["align"] = align }
    if let frame = frame { mergedAttributes["frame"] = frame }
    if let vlink = vlink { mergedAttributes["vlink"] = vlink }
    if let deferr = deferr { mergedAttributes["defer"] = deferr }
    if let color = color { mergedAttributes["color"] = color }
    if let media = media { mergedAttributes["media"] = media }
    if let title = title { mergedAttributes["title"] = title }
    if let scope = scope { mergedAttributes["scope"] = scope }
    if let classs = classs { mergedAttributes["class"] = classs }
    if let value = value { mergedAttributes["value"] = value }
    if let clear = clear { mergedAttributes["clear"] = clear }
    if let start = start { mergedAttributes["start"] = start }
    if let label = label { mergedAttributes["label"] = label }
    if let action = action { mergedAttributes["action"] = action }
    if let height = height { mergedAttributes["height"] = height }
    if let method = method { mergedAttributes["method"] = method }
    if let acceptt = acceptt { mergedAttributes["accept"] = acceptt }
    if let object = object { mergedAttributes["object"] = object }
    if let scheme = scheme { mergedAttributes["scheme"] = scheme }
    if let coords = coords { mergedAttributes["coords"] = coords }
    if let usemap = usemap { mergedAttributes["usemap"] = usemap }
    if let onblur = onblur { mergedAttributes["onblur"] = onblur }
    if let nohref = nohref { mergedAttributes["nohref"] = nohref }
    if let nowrap = nowrap { mergedAttributes["nowrap"] = nowrap }
    if let hspace = hspace { mergedAttributes["hspace"] = hspace }
    if let border = border { mergedAttributes["border"] = border }
    if let valign = valign { mergedAttributes["valign"] = valign }
    if let vspace = vspace { mergedAttributes["vspace"] = vspace }
    if let onload = onload { mergedAttributes["onload"] = onload }
    if let view = view { mergedAttributes["target"] = view }
    if let prompt = prompt { mergedAttributes["prompt"] = prompt }
    if let onfocus = onfocus { mergedAttributes["onfocus"] = onfocus }
    if let enctype = enctype { mergedAttributes["enctype"] = enctype }
    if let onclick = onclick { mergedAttributes["onclick"] = onclick }
    if let onkeyup = onkeyup { mergedAttributes["onkeyup"] = onkeyup }
    if let profile = profile { mergedAttributes["profile"] = profile }
    if let version = version { mergedAttributes["version"] = version }
    if let onreset = onreset { mergedAttributes["onreset"] = onreset }
    if let charset = charset { mergedAttributes["charset"] = charset }
    if let standby = standby { mergedAttributes["standby"] = standby }
    if let colspan = colspan { mergedAttributes["colspan"] = colspan }
    if let charoff = charoff { mergedAttributes["charoff"] = charoff }
    if let classid = classid { mergedAttributes["classid"] = classid }
    if let compact = compact { mergedAttributes["compact"] = compact }
    if let declare = declare { mergedAttributes["declare"] = declare }
    if let rowspan = rowspan { mergedAttributes["rowspan"] = rowspan }
    if let checked = checked { mergedAttributes["checked"] = checked }
    if let archive = archive { mergedAttributes["archive"] = archive }
    if let bgcolor = bgcolor { mergedAttributes["bgcolor"] = bgcolor }
    if let content = content { mergedAttributes["content"] = content }
    if let noshade = noshade { mergedAttributes["noshade"] = noshade }
    if let summary = summary { mergedAttributes["summary"] = summary }
    if let headers = headers { mergedAttributes["headers"] = headers }
    if let onselect = onselect { mergedAttributes["onselect"] = onselect }
    if let readonly = readonly { mergedAttributes["readonly"] = readonly }
    if let tabindex = tabindex { mergedAttributes["tabindex"] = tabindex }
    if let onchange = onchange { mergedAttributes["onchange"] = onchange }
    if let noresize = noresize { mergedAttributes["noresize"] = noresize }
    if let disabled = disabled { mergedAttributes["disabled"] = disabled }
    if let longdesc = longdesc { mergedAttributes["longdesc"] = longdesc }
    if let codebase = codebase { mergedAttributes["codebase"] = codebase }
    if let language = language { mergedAttributes["language"] = language }
    if let datetime = datetime { mergedAttributes["datetime"] = datetime }
    if let selected = selected { mergedAttributes["selected"] = selected }
    if let hreflang = hreflang { mergedAttributes["hreflang"] = hreflang }
    if let onsubmit = onsubmit { mergedAttributes["onsubmit"] = onsubmit }
    if let multiple = multiple { mergedAttributes["multiple"] = multiple }
    if let onunload = onunload { mergedAttributes["onunload"] = onunload }
    if let codetype = codetype { mergedAttributes["codetype"] = codetype }
    if let scrolling = scrolling { mergedAttributes["scrolling"] = scrolling }
    if let onkeydown = onkeydown { mergedAttributes["onkeydown"] = onkeydown }
    if let maxlength = maxlength { mergedAttributes["maxlength"] = maxlength }
    if let valuetype = valuetype { mergedAttributes["valuetype"] = valuetype }
    if let accesskey = accesskey { mergedAttributes["accesskey"] = accesskey }
    if let onmouseup = onmouseup { mergedAttributes["onmouseup"] = onmouseup }
    if let onkeypress = onkeypress { mergedAttributes["onkeypress"] = onkeypress }
    if let ondblclick = ondblclick { mergedAttributes["ondblclick"] = ondblclick }
    if let onmouseout = onmouseout { mergedAttributes["onmouseout"] = onmouseout }
    if let httpEquiv = httpEquiv { mergedAttributes["http-equiv"] = httpEquiv }
    if let background = background { mergedAttributes["background"] = background }
    if let onmousemove = onmousemove { mergedAttributes["onmousemove"] = onmousemove }
    if let onmouseover = onmouseover { mergedAttributes["onmouseover"] = onmouseover }
    if let cellpadding = cellpadding { mergedAttributes["cellpadding"] = cellpadding }
    if let onmousedown = onmousedown { mergedAttributes["onmousedown"] = onmousedown }
    if let frameborder = frameborder { mergedAttributes["frameborder"] = frameborder }
    if let marginwidth = marginwidth { mergedAttributes["marginwidth"] = marginwidth }
    if let cellspacing = cellspacing { mergedAttributes["cellspacing"] = cellspacing }
    if let placeholder = placeholder { mergedAttributes["placeholder"] = placeholder }
    if let marginheight = marginheight { mergedAttributes["marginheight"] = marginheight }
    if let acceptCharset = acceptCharset { mergedAttributes["accept-charset"] = acceptCharset }
    for item in attrs.enumerated() {
        mergedAttributes.updateValue(item.element.1, forKey: item.element.0)
    }
    output = output + mergedAttributes.reduce("") {
        if let value = $1.1 {
            return $0 + " \($1.0)=\"\(value)\""
        } else {
            return $0
        }
    }
    if let inner = inner {
        ScopesBuffer[Process.tid] = output + ">" + (inner) + "</" + node + ">"
    } else {
        let current = ScopesBuffer[Process.tid]  ?? ""
        ScopesBuffer[Process.tid] = output + ">" + current + "</" + node + ">"
    }

    idd = stackid
    dir = stackdir
    rel = stackrel
    rev = stackrev
    alt = stackalt
    forr = stackfor
    src = stacksrc
    type = stacktype
    href = stackhref
    text = stacktext
    abbr = stackabbr
    size = stacksize
    face = stackface
    char = stackchar
    cite = stackcite
    span = stackspan
    data = stackdata
    axis = stackaxis
    Name = stackName
    name = stackname
    code = stackcode
    link = stacklink
    lang = stacklang
    cols = stackcols
    rows = stackrows
    ismap = stackismap
    shape = stackshape
    style = stackstyle
    alink = stackalink
    width = stackwidth
    rules = stackrules
    align = stackalign
    frame = stackframe
    vlink = stackvlink
    deferr = stackdefer
    color = stackcolor
    media = stackmedia
    title = stacktitle
    scope = stackscope
    classs = stackclass
    value = stackvalue
    clear = stackclear
    start = stackstart
    label = stacklabel
    action = stackaction
    height = stackheight
    method = stackmethod
    acceptt = stackaccept
    object = stackobject
    scheme = stackscheme
    coords = stackcoords
    usemap = stackusemap
    onblur = stackonblur
    nohref = stacknohref
    nowrap = stacknowrap
    hspace = stackhspace
    border = stackborder
    valign = stackvalign
    vspace = stackvspace
    onload = stackonload
    view = stacktarget
    prompt = stackprompt
    onfocus = stackonfocus
    enctype = stackenctype
    onclick = stackonclick
    onkeyup = stackonkeyup
    profile = stackprofile
    version = stackversion
    onreset = stackonreset
    charset = stackcharset
    standby = stackstandby
    colspan = stackcolspan
    charoff = stackcharoff
    classid = stackclassid
    compact = stackcompact
    declare = stackdeclare
    rowspan = stackrowspan
    checked = stackchecked
    archive = stackarchive
    bgcolor = stackbgcolor
    content = stackcontent
    noshade = stacknoshade
    summary = stacksummary
    headers = stackheaders
    onselect = stackonselect
    readonly = stackreadonly
    tabindex = stacktabindex
    onchange = stackonchange
    noresize = stacknoresize
    disabled = stackdisabled
    longdesc = stacklongdesc
    codebase = stackcodebase
    language = stacklanguage
    datetime = stackdatetime
    selected = stackselected
    hreflang = stackhreflang
    onsubmit = stackonsubmit
    multiple = stackmultiple
    onunload = stackonunload
    codetype = stackcodetype
    scrolling = stackscrolling
    onkeydown = stackonkeydown
    maxlength = stackmaxlength
    valuetype = stackvaluetype
    accesskey = stackaccesskey
    onmouseup = stackonmouseup
    onkeypress = stackonkeypress
    ondblclick = stackondblclick
    onmouseout = stackonmouseout
    httpEquiv = stackhttpEquiv
    background = stackbackground
    onmousemove = stackonmousemove
    onmouseover = stackonmouseover
    cellpadding = stackcellpadding
    onmousedown = stackonmousedown
    frameborder = stackframeborder
    placeholder = stackplaceholder
    marginwidth = stackmarginwidth
    cellspacing = stackcellspacing
    marginheight = stackmarginheight
    acceptCharset = stackacceptCharset
    inner = stackinner
}

#if os(iOS) || os(tvOS) || os (Linux)
    struct sf_hdtr { }

    private func sendfileImpl(_ source: UnsafeMutablePointer<FILE>,
                              _ view: Int32,
                              _: off_t,
                              _: UnsafeMutablePointer<off_t>,
                              _: UnsafeMutablePointer<sf_hdtr>,
                              _: Int32) -> Int32 {
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let readResult = fread(&buffer, 1, buffer.count, source)
            guard readResult > 0 else {
                return Int32(readResult)
            }
            var writeCounter = 0
            while writeCounter < readResult {
                let writeResult = write(view, &buffer + writeCounter, readResult - writeCounter)
                guard writeResult > 0 else {
                    return Int32(writeResult)
                }
                writeCounter = writeCounter + writeResult
            }
        }
    }
#endif

extension Socket {

    func writeFile(_ file: String.File) throws -> Void {
        var offset: off_t = 0
        var sf: sf_hdtr = sf_hdtr()

        #if os(iOS) || os(tvOS) || os (Linux)
        let result = sendfileImpl(file.pointer, self.socketFileDescriptor, 0, &offset, &sf, 0)
        #else
        let result = sendfile(fileno(file.pointer), self.socketFileDescriptor, 0, &offset, &sf, 0)
        #endif

        if result == -1 {
            throw SocketError.writeFailed("sendfile: " + Errno.description())
        }
    }
}

extension Socket {
    class func tcpSocketForListen(_ port: in_port_t,
                                  _ forceIPv4: Bool = false,
                                  _ maxPendingConnection: Int32 = SOMAXCONN,
                                  _ listenAddress: String? = nil) throws -> Socket {
        #if os(Linux)
            let socketFileDescriptor =
                socket(forceIPv4 ? AF_INET : AF_INET6, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
        #endif

        if socketFileDescriptor == -1 {
            throw SocketError.socketCreationFailed(Errno.description())
        }

        var value: Int32 = 1
        if setsockopt(socketFileDescriptor,
                      SOL_SOCKET, SO_REUSEADDR,
                      &value,
                      socklen_t(MemoryLayout<Int32>.size)) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.socketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)

        var bindResult: Int32 = -1
        if forceIPv4 {
            #if os(Linux)
            var addr = sockaddr_in(
                sin_family: sa_family_t(AF_INET),
                sin_port: port.bigEndian,
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
            #else
            var addr = sockaddr_in(
                sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
                sin_family: UInt8(AF_INET),
                sin_port: port.bigEndian,
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
            #endif
            if let address = listenAddress {
              if address.withCString({
                cstring in inet_pton(AF_INET, cstring, &addr.sin_addr) }) == 1 {
                // print("\(address) is converted to \(addr.sin_addr).")
              } else {
                // print("\(address) is not converted.")
              }
            }
            bindResult = withUnsafePointer(to: &addr) {
                bind(socketFileDescriptor,
                     UnsafePointer<sockaddr>(OpaquePointer($0)),
                     socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        } else {
            #if os(Linux)
            var addr = sockaddr_in6(
                sin6_family: sa_family_t(AF_INET6),
                sin6_port: port.bigEndian,
                sin6_flowinfo: 0,
                sin6_addr: in6addr_any,
                sin6_scope_id: 0)
            #else
            var addr = sockaddr_in6(
                sin6_len: UInt8(MemoryLayout<sockaddr_in6>.stride),
                sin6_family: UInt8(AF_INET6),
                sin6_port: port.bigEndian,
                sin6_flowinfo: 0,
                sin6_addr: in6addr_any,
                sin6_scope_id: 0)
            #endif
            if let address = listenAddress {
              if address.withCString({
                cstring in inet_pton(AF_INET6, cstring, &addr.sin6_addr) }) == 1 {
                //print("\(address) is converted to \(addr.sin6_addr).")
              } else {
                //print("\(address) is not converted.")
              }
            }
            bindResult = withUnsafePointer(to: &addr) {
                bind(socketFileDescriptor,
                     UnsafePointer<sockaddr>(OpaquePointer($0)),
                     socklen_t(MemoryLayout<sockaddr_in6>.size))
            }
        }

        if bindResult == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.bindFailed(details)
        }

        if listen(socketFileDescriptor, maxPendingConnection) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.listenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }

    func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.acceptFailed(Errno.description())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
}

enum SocketError: Error {
    case socketCreationFailed(String)
    case socketSettingReUseAddrFailed(String)
    case bindFailed(String)
    case listenFailed(String)
    case writeFailed(String)
    case getPeerNameFailed(String)
    case convertingPeerNameFailed
    case getNameInfoFailed(String)
    case acceptFailed(String)
    case recvFailed(String)
    case getSockNameFailed(String)
}

class Socket: Hashable, Equatable {

    let socketFileDescriptor: Int32
    private var shutdown = false


    init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }

    deinit {
        close()
    }

    var hashValue: Int { return Int(self.socketFileDescriptor) }

    func close() {
        if shutdown {
            return
        }
        shutdown = true
        Socket.close(self.socketFileDescriptor)
    }

    func port() throws -> in_port_t {
        let addr = sockaddr_in()
        var localAddr = addr
        return try withUnsafePointer(to: &localAddr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor,
                           UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
            #if os(Linux)
                return ntohs(addr.sin_port)
            #else
                return Int(
                  OSHostByteOrder()) != OSLittleEndian
                  ? addr.sin_port.littleEndian : addr.sin_port.bigEndian
            #endif
        }
    }

    func isIPv4() throws -> Bool {
        let addr = sockaddr_in()
        var localAddr = addr
        return try withUnsafePointer(to: &localAddr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor,
                           UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
            return Int32(addr.sin_family) == AF_INET
        }
    }

    func writeUTF8(_ string: String) throws {
        try writeUInt8(ArraySlice(string.utf8))
    }

    func writeUInt8(_ data: [UInt8]) throws {
        try writeUInt8(ArraySlice(data))
    }

    func writeUInt8(_ data: ArraySlice<UInt8>) throws {
        try data.withUnsafeBufferPointer {
            try writeBuffer($0.baseAddress!, length: data.count)
        }
    }

    func writeData(_ data: NSData) throws {
        try writeBuffer(data.bytes, length: data.length)
    }

    func writeData(_ data: Data) throws {
        try data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Void in
            try self.writeBuffer(pointer, length: data.count)
        }
    }

    private func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws {
        var sent = 0
        while sent < length {
            #if os(Linux)
                let s = send(self.socketFileDescriptor,
                             pointer + sent, Int(length - sent), Int32(MSG_NOSIGNAL))
            #else
                let s = write(self.socketFileDescriptor, pointer + sent, Int(length - sent))
            #endif
            if s <= 0 {
                throw SocketError.writeFailed(Errno.description())
            }
            sent += s
        }
    }

    func read() throws -> UInt8 {
        var buffer = [UInt8](repeating: 0, count: 1)
        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            throw SocketError.recvFailed(Errno.description())
        }
        return buffer[0]
    }

    private static let CR = UInt8(13)
    private static let NL = UInt8(10)

    func readLine() throws -> String {
        var characters: String = ""
        var n: UInt8 = 0
        repeat {
            n = try self.read()
            if n > Socket.CR { characters.append(Character(UnicodeScalar(n))) }
        } while n != Socket.NL
        return characters
    }

    func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.getPeerNameFailed(Errno.description())
        }
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(&addr,
                       len,
                       &hostBuffer,
                       socklen_t(hostBuffer.count),
                       nil,
                       0,
                       NI_NUMERICHOST) != 0 {
            throw SocketError.getNameInfoFailed(Errno.description())
        }
        return String(cString: hostBuffer)
    }

    class func setNoSigPipe(_ socket: Int32) {
        #if os(Linux)
        #else
            var no_sig_pipe: Int32 = 1
            setsockopt(socket,
                       SOL_SOCKET,
                       SO_NOSIGPIPE,
                       &no_sig_pipe,
                       socklen_t(MemoryLayout<Int32>.size))
        #endif
    }

    class func close(_ socket: Int32) {
        #if os(Linux)
            let _ = Glibc.close(socket)
        #else
            let _ = Darwin.close(socket)
        #endif
    }
}

func == (socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}

extension String {

    private static let CODES =
        [UInt8]("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".utf8)
    static func toBase64(_ data: [UInt8]) -> String? {

        // Based on: https://en.wikipedia.org/wiki/Base64#Sample_Implementation_in_Java

        var result = [UInt8]()
        var tmp: UInt8
        for index in stride(from: 0, to: data.count, by: 3) {
            let byte = data[index]
            tmp = (byte & 0xFC) >> 2;
            result.append(CODES[Int(tmp)])
            tmp = (byte & 0x03) << 4;
            if index + 1 < data.count {
                tmp |= (data[index + 1] & 0xF0) >> 4;
                result.append(CODES[Int(tmp)]);
                tmp = (data[index + 1] & 0x0F) << 2;
                if (index + 2 < data.count)  {
                    tmp |= (data[index + 2] & 0xC0) >> 6;
                    result.append(CODES[Int(tmp)]);
                    tmp = data[index + 2] & 0x3F;
                    result.append(CODES[Int(tmp)]);
                } else  {
                    result.append(CODES[Int(tmp)]);
                    result.append(contentsOf: [UInt8]("=".utf8));
                }
            } else {
                result.append(CODES[Int(tmp)]);
                result.append(contentsOf: [UInt8]("==".utf8));
            }
        }
        return String(bytes: result, encoding: .utf8)
    }
}

extension String {

    enum FileError: Error {
        case error(Int32)
    }

    class File {

        let pointer: UnsafeMutablePointer<FILE>

        init(_ pointer: UnsafeMutablePointer<FILE>) {
            self.pointer = pointer
        }

        func close() -> Void {
            fclose(pointer)
        }

        func seek(_ offset: Int) -> Bool {
            return (fseek(pointer, offset, SEEK_SET) == 0)
        }

        func read(_ data: inout [UInt8]) throws -> Int {
            if data.count <= 0 {
                return data.count
            }
            let count = fread(&data, 1, data.count, self.pointer)
            if count == data.count {
                return count
            }
            if feof(self.pointer) != 0 {
                return count
            }
            if ferror(self.pointer) != 0 {
                throw FileError.error(errno)
            }
            throw FileError.error(0)
        }

        func write(_ data: [UInt8]) throws -> Void {
            if data.count <= 0 {
                return
            }
            try data.withUnsafeBufferPointer {
                if fwrite($0.baseAddress, 1, data.count, self.pointer) != data.count {
                    throw FileError.error(errno)
                }
            }
        }

        static func currentWorkingDirectory() throws -> String {
            guard let path = getcwd(nil, 0) else {
                throw FileError.error(errno)
            }
            return String(cString: path)
        }
    }

    static var pathSeparator = "/"

    func openNewForWriting() throws -> File {
        return try openFileForMode(self, "wb")
    }

    func openForReading() throws -> File {
        return try openFileForMode(self, "rb")
    }

    func openForWritingAndReading() throws -> File {
        return try openFileForMode(self, "r+b")
    }

    func openFileForMode(_ path: String, _ mode: String) throws -> File {
        guard let file = path.withCString({
          pathPointer in mode.withCString({ fopen(pathPointer, $0) })
        }) else {
            throw FileError.error(errno)
        }
        return File(file)
    }

    func exists() throws -> Bool {
        return try self.withStat {
            if let _ = $0 {
                return true
            }
            return false
        }
    }

    func directory() throws -> Bool {
        return try self.withStat {
            if let stat = $0 {
                return stat.st_mode & S_IFMT == S_IFDIR
            }
            return false
        }
    }

    func files() throws -> [String] {
        guard let dir = self.withCString({ opendir($0) }) else {
            throw FileError.error(errno)
        }
        defer { closedir(dir) }
        var results = [String]()
        while let ent = readdir(dir) {
            var name = ent.pointee.d_name
            let fileName = withUnsafePointer(to: &name) { (ptr) -> String? in
                #if os(Linux)
                    return String(validatingUTF8: [CChar](
                      UnsafeBufferPointer<CChar>(
                        start: UnsafePointer(unsafeBitCast(ptr, to: UnsafePointer<CChar>.self)),
                        count: 256)))
                #else
                    var buffer = ptr.withMemoryRebound(to: CChar.self,
                                                       capacity: Int(ent.pointee.d_reclen), {
                      (ptrc) -> [CChar] in
                      return [CChar](UnsafeBufferPointer(start: ptrc,
                                                         count: Int(ent.pointee.d_namlen)))
                    })
                    buffer.append(0)
                    return String(validatingUTF8: buffer)
                #endif
            }
            if let fileName = fileName {
                results.append(fileName)
            }
        }
        return results
    }

    private func withStat<T>(_ closure: ((stat?) throws -> T)) throws -> T {
        return try self.withCString({
            var statBuffer = stat()
            if stat($0, &statBuffer) == 0 {
                return try closure(statBuffer)
            }
            if errno == ENOENT {
                return try closure(nil)
            }
            throw FileError.error(errno)
        })
    }
}

extension String {
    func unquote() -> String {
        var scalars = self.unicodeScalars;
        if scalars.first == "\"" && scalars.last == "\"" && scalars.count >= 2 {
            scalars.removeFirst();
            scalars.removeLast();
            return String(scalars)
        }
        return self
    }
}

extension UnicodeScalar {

    func asWhitespace() -> UInt8? {
        if self.value >= 9 && self.value <= 13 {
            return UInt8(self.value)
        }
        if self.value == 32 {
            return UInt8(self.value)
        }
        return nil
    }
}

struct SHA1 {

    static func hash(_ input: [UInt8]) -> [UInt8] {

        // Alghorithm from: https://en.wikipedia.org/wiki/SHA-1

        var message = input

        var h0 = UInt32(littleEndian: 0x67452301)
        var h1 = UInt32(littleEndian: 0xEFCDAB89)
        var h2 = UInt32(littleEndian: 0x98BADCFE)
        var h3 = UInt32(littleEndian: 0x10325476)
        var h4 = UInt32(littleEndian: 0xC3D2E1F0)
        let ml = UInt64(message.count * 8)
        message.append(0x80)
        let padBytesCount = ( message.count + 8 ) % 64
        message.append(contentsOf: [UInt8](repeating: 0, count: 64 - padBytesCount))
        var mlBigEndian = ml.bigEndian
        withUnsafePointer(to: &mlBigEndian) {
            message.append(
              contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer(OpaquePointer($0)),
                                                           count: 8)))
        }
        for chunkStart in 0..<message.count/64 {
            var words = [UInt32]()
            let chunk = message[chunkStart*64..<chunkStart*64+64]
            for i in 0...15 {
                let value = chunk.withUnsafeBufferPointer({
                  UnsafePointer<UInt32>(OpaquePointer($0.baseAddress! + (i*4))).pointee})
                words.append(value.bigEndian)
            }
            for i in 16...79 {
                let value: UInt32 = ((words[i-3]) ^ (words[i-8]) ^ (words[i-14]) ^ (words[i-16]))
                words.append(rotateLeft(value, 1))
            }
            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            for i in 0..<80 {
                var f = UInt32(0)
                var k = UInt32(0)
                switch i {
                case 0...19:
                    f = (b & c) | ((~b) & d)
                    k = 0x5A827999
                case 20...39:
                    f = b ^ c ^ d
                    k = 0x6ED9EBA1
                case 40...59:
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8F1BBCDC
                case 60...79:
                    f = b ^ c ^ d
                    k = 0xCA62C1D6
                default: break
                }
                let temp = (rotateLeft(a, 5) &+ f &+ e &+ k &+ words[i]) & 0xFFFFFFFF
                e = d
                d = c
                c = rotateLeft(b, 30)
                b = a
                a = temp
            }
            h0 = ( h0 &+ a ) & 0xFFFFFFFF
            h1 = ( h1 &+ b ) & 0xFFFFFFFF
            h2 = ( h2 &+ c ) & 0xFFFFFFFF
            h3 = ( h3 &+ d ) & 0xFFFFFFFF
            h4 = ( h4 &+ e ) & 0xFFFFFFFF
        }
        var digest = [UInt8]()
        [h0, h1, h2, h3, h4].forEach { value in
            var bigEndianVersion = value.bigEndian
            withUnsafePointer(to: &bigEndianVersion) {
                digest.append(contentsOf:Array(UnsafeBufferPointer<UInt8>(
                  start: UnsafePointer(OpaquePointer($0)),
                  count: 4)))
            }
        }
        return digest
    }

    private static func rotateLeft(_ v: UInt32, _ n: UInt32) -> UInt32 {
        return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
    }
}

extension String {
    func sha1() -> [UInt8] {
        return SHA1.hash([UInt8](self.utf8))
    }
    func sha1() -> String {
        return self.sha1().reduce("") { $0 + String(format: "%02x", $1) }
    }
}

func websocket(
      _ text: ((WebSocketSession, String) -> Void)?,
    _ binary: ((WebSocketSession, [UInt8]) -> Void)?) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        guard r.hasTokenForHeader("upgrade", token: "websocket") else {
            return .badRequest(
            .text("Invalid value of 'Upgrade' header: \(r.headers["upgrade"] ?? "unknown")"))
        }
        guard r.hasTokenForHeader("connection", token: "upgrade") else {
            return .badRequest(
            .text("Invalid value of 'Connection' header: \(r.headers["connection"] ?? "unknown")"))
        }
        guard let secWebSocketKey = r.headers["sec-websocket-key"] else {
            return .badRequest(
            .text("Invalid value."))
        }
        let protocolSessionClosure: ((Socket) -> Void) = { socket in
            let session = WebSocketSession(socket)
            var fragmentedOpCode = WebSocketSession.OpCode.close
            var payload = [UInt8]() // Used for fragmented frames.

            func handleTextPayload(_ frame: WebSocketSession.Frame) throws {
                if let handleText = text {
                    if frame.fin {
                        if payload.count > 0 {
                            throw WebSocketSession.WsError.protocolError("")
                        }
                        var textFramePayload = frame.payload.map { Int8(bitPattern: $0) }
                        textFramePayload.append(0)
                        if let text = String(validatingUTF8: textFramePayload) {
                            handleText(session, text)
                        } else {
                            throw WebSocketSession.WsError.invalidUTF8("")
                        }
                    } else {
                        payload.append(contentsOf: frame.payload)
                        fragmentedOpCode = .text
                    }
                }
            }

            func handleBinaryPayload(_ frame: WebSocketSession.Frame) throws {
                if let handleBinary = binary {
                    if frame.fin {
                        if payload.count > 0 {
                            throw WebSocketSession.WsError.protocolError("")
                        }
                        handleBinary(session, frame.payload)
                    } else {
                        payload.append(contentsOf: frame.payload)
                        fragmentedOpCode = .binary
                    }
                }
            }

            func handleOperationCode(_ frame: WebSocketSession.Frame) throws {
                switch frame.opcode {
                case .continue:
                    // There is no message to continue, failed immediatelly.
                    if fragmentedOpCode == .close {
                        socket.close()
                    }
                    frame.opcode = fragmentedOpCode
                    if frame.fin {
                        payload.append(contentsOf: frame.payload)
                        frame.payload = payload
                        // Clean the buffer.
                        payload = []
                        // Reset the OpCode.
                        fragmentedOpCode = WebSocketSession.OpCode.close
                    }
                    try handleOperationCode(frame)
                case .text:
                    try handleTextPayload(frame)
                case .binary:
                    try handleBinaryPayload(frame)
                case .close:
                    throw WebSocketSession.Control.close
                case .ping:
                    if frame.payload.count > 125 {
                        throw WebSocketSession.WsError.protocolError("")
                    } else {
                        session.writeFrame(ArraySlice(frame.payload), .pong)
                    }
                case .pong:
                    break
                }
            }
            do {
                while true {
                    let frame = try session.readFrame()
                    try handleOperationCode(frame)
                }
            } catch let error {
                switch error {
                case WebSocketSession.Control.close:
                    // Normal close
                    break
                case WebSocketSession.WsError.unknownOpCode:
                    print("Unknown Op Code: \(error)")
                case WebSocketSession.WsError.unMaskedFrame:
                    print("Unmasked frame: \(error)")
                case WebSocketSession.WsError.invalidUTF8:
                    print("Invalid UTF8 character: \(error)")
                case WebSocketSession.WsError.protocolError:
                    print("Protocol error: \(error)")
                default:
                    print("Unkown error \(error)")
                }
                // If an error occurs, send the close handshake.
                session.writeCloseFrame()
            }
        }
        guard let secWebSocketAccept =
          String.toBase64((secWebSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").sha1()) else {
            return HttpResponse.internalServerError
        }
        let headers =
          ["Upgrade": "WebSocket",
           "Connection": "Upgrade",
           "Sec-WebSocket-Accept": secWebSocketAccept]
        return HttpResponse.switchProtocols(headers, protocolSessionClosure)
    }
}

class WebSocketSession: Hashable, Equatable  {

  enum WsError: Error {
    case unknownOpCode(String)
    case unMaskedFrame(String)
    case protocolError(String)
    case invalidUTF8(String)
  }
  enum OpCode: UInt8 {
    case `continue` = 0x00
    case close = 0x08
    case ping = 0x09
    case pong = 0x0A
    case text = 0x01
    case binary = 0x02
  }
    enum Control: Error { case close }

    class Frame {
        var opcode = OpCode.close
        var fin = false
        var rsv1: UInt8 = 0
        var rsv2: UInt8 = 0
        var rsv3: UInt8 = 0
        var payload = [UInt8]()
    }

    let socket: Socket

    init(_ socket: Socket) {
        self.socket = socket
    }

    deinit {
        writeCloseFrame()
        socket.close()
    }

    func writeText(_ text: String) -> Void {
        self.writeFrame(ArraySlice(text.utf8), OpCode.text)
    }

    func writeBinary(_ binary: [UInt8]) -> Void {
        self.writeBinary(ArraySlice(binary))
    }

    func writeBinary(_ binary: ArraySlice<UInt8>) -> Void {
        self.writeFrame(binary, OpCode.binary)
    }

    func writeFrame(_ data: ArraySlice<UInt8>, _ op: OpCode, _ fin: Bool = true) {
        let finAndOpCode = UInt8(fin ? 0x80 : 0x00) | op.rawValue
        let maskAndLngth = encodeLengthAndMaskFlag(UInt64(data.count), false)
        do {
            try self.socket.writeUInt8([finAndOpCode])
            try self.socket.writeUInt8(maskAndLngth)
            try self.socket.writeUInt8(data)
        } catch {
            print(error)
        }
    }

    func writeCloseFrame() {
        writeFrame(ArraySlice("".utf8), .close)
    }

    private func encodeLengthAndMaskFlag(_ len: UInt64, _ masked: Bool) -> [UInt8] {
        let encodedLngth = UInt8(masked ? 0x80 : 0x00)
        var encodedBytes = [UInt8]()
        switch len {
        case 0...125:
            encodedBytes.append(encodedLngth | UInt8(len));
        case 126...UInt64(UINT16_MAX):
            encodedBytes.append(encodedLngth | 0x7E);
            encodedBytes.append(UInt8(len >> 8 & 0xFF));
            encodedBytes.append(UInt8(len >> 0 & 0xFF));
        default:
            encodedBytes.append(encodedLngth | 0x7F);
            encodedBytes.append(UInt8(len >> 56 & 0xFF));
            encodedBytes.append(UInt8(len >> 48 & 0xFF));
            encodedBytes.append(UInt8(len >> 40 & 0xFF));
            encodedBytes.append(UInt8(len >> 32 & 0xFF));
            encodedBytes.append(UInt8(len >> 24 & 0xFF));
            encodedBytes.append(UInt8(len >> 16 & 0xFF));
            encodedBytes.append(UInt8(len >> 08 & 0xFF));
            encodedBytes.append(UInt8(len >> 00 & 0xFF));
        }
        return encodedBytes
    }

    func readFrame() throws -> Frame {
        let frm = Frame()
        let fst = try socket.read()
        frm.fin = fst & 0x80 != 0
        frm.rsv1 = fst & 0x40
        frm.rsv2 = fst & 0x20
        frm.rsv3 = fst & 0x10
        guard frm.rsv1 == 0 && frm.rsv2 == 0 && frm.rsv3 == 0
            else {
            throw WsError.protocolError("Reserved frame bit has not been negocitated.")
        }
        let opc = fst & 0x0F
        guard let opcode = OpCode(rawValue: opc) else {
            // http://tools.ietf.org/html/rfc6455#section-5.2 ( Page 29 )
            throw WsError.unknownOpCode("\(opc)")
        }
        if frm.fin == false {
            switch opcode {
            case .ping, .pong, .close:
                // Control frames must not be fragmented
                // https://tools.ietf.org/html/rfc6455#section-5.5 ( Page 35 )
                throw WsError.protocolError("Control frames must not be fragmented.")
            default:
                break
            }
        }
        frm.opcode = opcode
        let sec = try socket.read()
        let msk = sec & 0x80 != 0
        guard msk else {
            // "...a client MUST mask all frames that it sends to the server."
            // http://tools.ietf.org/html/rfc6455#section-5.1
            throw WsError.unMaskedFrame("")
        }
        var len = UInt64(sec & 0x7F)
        if len == 0x7E {
            let b0 = UInt64(try socket.read())
            let b1 = UInt64(try socket.read())
            len = UInt64(littleEndian: b0 << 8 | b1)
        } else if len == 0x7F {
            let b0 = UInt64(try socket.read())
            let b1 = UInt64(try socket.read())
            let b2 = UInt64(try socket.read())
            let b3 = UInt64(try socket.read())
            let b4 = UInt64(try socket.read())
            let b5 = UInt64(try socket.read())
            let b6 = UInt64(try socket.read())
            let b7 = UInt64(try socket.read())
            len = UInt64(littleEndian:
              b0 << 54 | b1 << 48 | b2 << 40 | b3 << 32 | b4 << 24 | b5 << 16 | b6 << 8 | b7)
        }
        let mask = [try socket.read(), try socket.read(), try socket.read(), try socket.read()]
        for i in 0..<len {
            frm.payload.append(try socket.read() ^ mask[Int(i % 4)])
        }
        return frm
    }

    var hashValue: Int {
        get {
            return socket.hashValue
        }
    }
}

func ==(webSocketSession1: WebSocketSession, webSocketSession2: WebSocketSession) -> Bool {
    return webSocketSession1.socket == webSocketSession2.socket
}
#endif


