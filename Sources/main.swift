#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

import Foundation
import Socket
import Dispatch

class EchoServer {
  let bufferSize = 1024
  let port: Int

  var listenSocket: Socket? = nil
  var connected = [Int32: Socket]()
  var acceptNewConnection = true

  init(port: Int) {
    self.port = port
  }

  deinit {
    for socket in connected.values {
      socket.close()
    }

    listenSocket?.close()
  }

  func start() throws {
    let socket = try Socket.create()
    listenSocket = socket
    try socket.listen(on: port)

    print("Listening port: \(socket.listeningPort)")
    let queue = DispatchQueue(label: "xho95", attributes: .concurrent)

    repeat {
      let connectedSocket = try socket.acceptClientConnection()
      print("Connection from: \(connectedSocket.remoteHostname)")
      queue.async{
          self.newConnection(socket: connectedSocket)
      }
    } while acceptNewConnection
  }

  func newConnection(socket: Socket) {
    connected[socket.socketfd] = socket
    var cont = true
    var dataRead = Data(capacity: bufferSize)

    repeat {
      do {
        let bytes = try socket.read(into: &dataRead)
        if bytes > 0 {
          if let readStr = String(data: dataRead, encoding: .utf8) {
            print("Received: \(readStr)")
            try socket.write(from: readStr)
            if readStr.hasPrefix("quit") {
              cont = false
              socket.close()
            }
            dataRead.count = 0
          }
        }
      }
      catch let error {
        print("error: \(error)")
      }
    } while cont

    connected.removeValue(forKey: socket.socketfd)
    socket.close()
  }
}

let server = EchoServer(port: 3333)

do {
  try server.start()
}
catch let error {
  print("Error: \(error)")
}
