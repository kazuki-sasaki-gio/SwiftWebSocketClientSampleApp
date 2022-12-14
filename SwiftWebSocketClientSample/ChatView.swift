//
//  ChatView.swift
//  SwiftWebSocketClientSample
//
//  Created by Akira Shimizu on 2020/12/05.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var client: WebSocketClient
    @State private var message = ""

    init() {
        client = WebSocketClient()
        client.setup(url: "")
    }

    var body: some View {
        VStack {
            if client.isConnected {
                Button(action: {
                    client.load()
                }) {
                    Text("load()")
                }
                List {
                    ForEach(client.messages.indices, id: \.self) { index in
                        Text(client.messages[index])
                    }
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
            HStack(alignment: .center, spacing: 16, content: {
                TextField("コメント", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("send") {
                    if !message.isEmpty {
                        client.send(message)
                        message = ""
                    }
                }
                .disabled(!client.isConnected)
            })
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onAppear() {
            client.connect()
        }
//        .onDisappear() {
//            client.disconnect()
//        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
