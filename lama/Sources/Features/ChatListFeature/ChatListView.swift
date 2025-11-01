//
//  ChatListView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct ChatListView: View {
  @Bindable var store: StoreOf<ChatList>
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      Group {
        if store.chats.isEmpty {
          NoChatsMessage()
        } else {
          List {
            ForEach(store.chats) { chat in
              NavigationLink(
                "New chat",
                state: ChatList.Path.State.chat(Chat.State(id: chat.id))
              )
            }
          }
        }
      }
      .navigationTitle("Chats")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: { store.send(.newChatButtonTapped) }) {
            Image(systemName: "plus")
          }
        }
      }
    } destination: { store in
      switch store.case {
      case let .chat(store):
        ChatView(store: store)
      }
    }
  }
}

#Preview {
  ChatListView(
    store: Store(initialState: ChatList.State()) {
      ChatList()
    }
  )
}

