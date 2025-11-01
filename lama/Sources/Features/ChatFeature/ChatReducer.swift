//
//  ChatReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Chat {
  @Dependency(\.ollamaService) var ollamaService
  
  @ObservableState
  struct State: Equatable, Identifiable {
    let id: UUID
    var model: String = "gemma3:4b"
    var errorMessage: String?
    var isLoading: Bool = false
    var messages: IdentifiedArrayOf<Message.State> = []
    var messageInputState = MessageInput.State()
  }
  
  enum Action {
    case messages(IdentifiedActionOf<Message>)
    case messageInput(MessageInput.Action)
    case onAppear
    case streamingResponseReceived(String)
    case streamingComplete
    case streamingError(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
        
      case .messageInput(.delegate(.sendMessage)):
        let inputText = state.messageInputState.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inputText.isEmpty else {
          return .none
        }
        
        // Clear input
        state.messageInputState.inputText = ""
        state.messageInputState.isLoading = true
        state.errorMessage = nil
        
        // Add user message
        let userMessageId = UUID()
        let userMessage = Message.State(
          id: userMessageId,
          role: .user,
          content: inputText
        )
        state.messages.append(userMessage)
        
        // Convert existing messages (including the user message we just added) to ChatMessage format for Ollama
        // We'll add the assistant placeholder after converting
        let chatMessages = state.messages.map { message in
          ChatMessage(role: message.role, content: message.content)
        }
        
        // Create assistant message placeholder for streaming
        let assistantMessageId = UUID()
        let assistantMessage = Message.State(
          id: assistantMessageId,
          role: .assistant,
          content: ""
        )
        state.messages.append(assistantMessage)
        state.isLoading = true
        
        // Start streaming request
        return .run { [model = state.model] send in
          do {
            let stream = try await ollamaService.chat(
              model: model,
              messages: chatMessages
            )
            
            for try await response in stream {
              if let messageContent = response.message?.content {
                await send(.streamingResponseReceived(messageContent))
              }
              
              if response.done == true {
                await send(.streamingComplete)
                break
              }
            }
          } catch {
            await send(.streamingError(error.localizedDescription))
          }
        }
        
      case .streamingResponseReceived(let content):
        // Update the last message (assistant message) with streaming content
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          state.messages[lastIndex].content += content
        }
        return .none
        
      case .streamingComplete:
        state.isLoading = false
        state.messageInputState.isLoading = false
        return .none
        
      case .streamingError(let errorMessage):
        state.isLoading = false
        state.messageInputState.isLoading = false
        state.errorMessage = errorMessage
        // Remove the empty assistant message if there was an error
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant,
           state.messages[lastIndex].content.isEmpty {
          state.messages.remove(at: lastIndex)
        }
        return .none
        
      case .messageInput:
        return .none
        
      case .messages:
        return .none
      }
    }
    .forEach(\.messages, action: \.messages) {
      Message()
    }

    Scope(state: \.messageInputState, action: \.messageInput) {
      MessageInput()
    }
  }
}
