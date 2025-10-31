//
//  HomeView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
  var store: StoreOf<Home>
  @FocusState private var isInputFocused: Bool
  
  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Chat")
          .font(.title2)
          .fontWeight(.medium)
        Spacer()
        TextField("Model", text: Binding(
          get: { store.model },
          set: { store.send(.modelChanged($0)) }
        ))
        .textFieldStyle(.roundedBorder)
        .frame(width: 120)
      }
      .padding()
      
      Divider()
      
      // Messages
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(store.messages) { message in
              MessageBubble(message: message)
                .id(message.id)
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
          if let lastMessage = store.messages.last {
            withAnimation {
              proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
        }
        .onChange(of: store.isLoading) { _, isLoading in
          if isLoading, let lastMessage = store.messages.last {
            withAnimation {
              proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
        }
      }
      
      // Input
      HStack(spacing: 12) {
        TextField("Type a message...", text: Binding(
          get: { store.inputText },
          set: { store.send(.inputTextChanged($0)) }
        ), axis: .vertical)
        .lineLimit(1...5)
        .focused($isInputFocused)
        .onSubmit {
          if !store.inputText.isEmpty {
            store.send(.sendMessage)
            isInputFocused = true
          }
        }
        
        Button {
          store.send(.sendMessage)
          isInputFocused = true
        } label: {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title)
            .foregroundColor(store.inputText.isEmpty || store.isLoading ? .gray : .blue)
        }
        .disabled(store.inputText.isEmpty || store.isLoading)
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 24)
      .background(.colorGray)
      .clipShape(Capsule())
      .padding()
    }
    .onAppear {
      store.send(.onAppear)
      isInputFocused = true
    }
  }
}

struct MessageBubble: View {
  let message: UIMessage
  
  var body: some View {
    HStack {
      if message.role == .user {
        Spacer()
      }
      
      VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
        Text(message.content)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(
            message.role == .user
            ? Color.blue.opacity(0.2)
            : Color(uiColor: .systemGray6)
          )
          .cornerRadius(12)
      }
      .frame(maxWidth: .infinity * 0.75, alignment: message.role == .user ? .trailing : .leading)
      
      if message.role == .assistant {
        Spacer()
      }
    }
  }
}

#Preview {
  HomeView(
    store: Store(initialState: Home.State()) {
      Home()
    }
  )
}

