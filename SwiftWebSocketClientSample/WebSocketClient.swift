//
//  WebSocketClient.swift
//  SwiftWebSocketClientSample
//
//  Created by Akira Shimizu on 2020/12/05.
//

import Foundation
import Starscream

final class WebSocketClient: NSObject, ObservableObject {
    
    private var socket: WebSocket?
    
    @Published var messages: [String] = []
    @Published var isConnected: Bool = false
    
    deinit {
        socket?.disconnect()
        socket?.delegate = nil
    }
    
    func setup(url: String) {
        var request = URLRequest(url: URL(string: url)!)
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": String(format: "Bearer %@", "eyJhbGciOiJSUzI1NiIsImtpZCI6ImY4MDljZmYxMTZlNWJhNzQwNzQ1YmZlZGE1OGUxNmU4MmYzZmQ4MDUiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdHJ5LW91dC01M2EzZCIsImF1ZCI6InRyeS1vdXQtNTNhM2QiLCJhdXRoX3RpbWUiOjE2Njc5MDEyMTEsInVzZXJfaWQiOiJDNHNENmVhMFR6YzFrdXNQZEFSdUhWaTB1c0UzIiwic3ViIjoiQzRzRDZlYTBUemMxa3VzUGRBUnVIVmkwdXNFMyIsImlhdCI6MTY2ODc1MTI3MSwiZXhwIjoxNjY4NzU0ODcxLCJlbWFpbCI6ImNhbnRhdGUuMTAwOS4wNDE3QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7ImVtYWlsIjpbImNhbnRhdGUuMTAwOS4wNDE3QGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIiwic2lnbl9pbl9zZWNvbmRfZmFjdG9yIjoicGhvbmUiLCJzZWNvbmRfZmFjdG9yX2lkZW50aWZpZXIiOiI2NDlhOWE0Ni0xNjYyLTRiMGItYjEyNS04ZTI2NWNiY2EyMmIifX0.qhBnRiqtrElLQkVnLpFrbI_RITNbyYlZ-Y0jc_Vws_-hiVuWMjFnPybzTC4GJhvRdgc6eHKV8og5FFI731v5nFM0H1a5P0wEeqG3Soma4DTqSA_tFOBYZQhaX3_XLGRL1SmntXtUoag9JA98htRC8jJ60ADE5DP455SHOCu4h6Re4CPoe4rrz5o4rxQQp5WzUhThUn_EiGk4yoCFA04YBzO7-ONVVTT_lnctGSoP-pfwRQMqU6xsR-FVoc-w9k1dCMT87v7ISvtGmXq8_Y3jDrBFVhw0pFZU9juwS-PMO7bXgFx1HnF8CXdO-kC0ISe-Q9ASnWmVuVpMqLL-77EnUQ"),
        ]
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
    }
    
    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func send(_ message: String) {
        let sendData = MessageRequest(data: message, userId: "user001", transactionID: "test_transaction_id")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try? encoder.encode(sendData)
        socket?.write(string: String(decoding: jsonData ?? Data(), as: UTF8.self))
//        print(String(decoding: jsonData ?? Data(), as: UTF8.self))
    }
    
    func load() {
        let loadAction = LoadAction(transactionID: "test_transaction_id")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try? encoder.encode(loadAction)
        socket?.write(string: String(decoding: jsonData ?? Data(), as: UTF8.self))
//        print(String(decoding: jsonData ?? Data(), as: UTF8.self))
    }
}

extension WebSocketClient: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let jsonStr):
            print("Received text: \(jsonStr)")
            let jsonData = String(jsonStr).data(using: .utf8)!
            do {
                let decoder: JSONDecoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.yyyyMMddHHmmss)
                let message = try decoder.decode(MessageResponse.self, from: jsonData)
                print(message.data)
                print(message.createdDatetime)
                print(message.userID)
                messages.append(message.data)
            } catch {
                print(error.localizedDescription)
            }
        case .binary(let data):
            print("Received data: \(data.count)")
            
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            print(error?.localizedDescription)
        }
    }
}

struct MessageRequest: Encodable {
    var action: String = "sendmessage"
    var data: String
    var userId: String
    var transactionID: String
}

struct MessageResponse: Codable {
    var data: String
    var userID: String
    var createdDatetime: Date
}

struct LoadAction: Encodable {
    var action: String = "load"
    var transactionID: String
}

extension DateFormatter {
    static let yyyyMMddHHmmss: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
