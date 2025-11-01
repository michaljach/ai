//
//  ChatView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct ChatView: View {
  var store: StoreOf<Chat>
  
  var body: some View {
    VStack(spacing: 0) {
      // Messages List
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(store.scope(state: \.messages, action: \.messages)) { store in
              MessageView(store: store)
            }
            
            if store.isLoading {
              HStack {
                ProgressView()
                  .scaleEffect(0.8)
                Text("Thinking...")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding(.horizontal)
            }
            
            if let error = store.errorMessage {
              Text("Error: \(error)")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal)
            }
          }
          .padding()
        }
        .onChange(of: store.messages.count) { oldCount, newCount in
          if let lastMessageState = store.messages.last {
            withAnimation {
              proxy.scrollTo(lastMessageState.id, anchor: .bottom)
            }
          }
        }
        .onChange(of: store.isLoading) { _, isLoading in
          if isLoading, let lastMessageState = store.messages.last {
            withAnimation {
              proxy.scrollTo(lastMessageState.id, anchor: .bottom)
            }
          }
        }
      }
      
      // Input
      MessageInputView(
        store: store.scope(state: \.messageInputState, action: \.messageInput)
      )
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}


#Preview {
  ChatView(
    store: Store(initialState: Chat.State(id: UUID())) {
      Chat()
    }
  )
}

