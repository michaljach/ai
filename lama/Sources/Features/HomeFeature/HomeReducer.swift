//
//  HomeReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

struct UIMessage: Identifiable, Equatable {
  let id: UUID
  let role: MessageRole
  var content: String
  
  init(id: UUID = UUID(), role: MessageRole, content: String) {
    self.id = id
    self.role = role
    self.content = content
  }
}

@Reducer
struct Home {
  @Dependency(\.ollamaService) var ollamaService
  
  @ObservableState
  struct State: Equatable {
    var messages: [UIMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var model: String = "llama2"
    var errorMessage: String?
  }
  
  enum Action {
    case onAppear
    case inputTextChanged(String)
    case modelChanged(String)
    case sendMessage
    case messageReceived(String)
    case streamChunk(ChatResponse)
    case streamFinished
    case errorOccurred(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
        
      case .inputTextChanged(let text):
        state.inputText = text
        return .none
        
      case .modelChanged(let model):
        state.model = model
        return .none
        
      case .sendMessage:
        guard !state.inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
          return .none
        }
        
        let userMessage = UIMessage(role: .user, content: state.inputText)
        state.messages.append(userMessage)
        state.isLoading = true
        state.errorMessage = nil
        let currentMessages = state.messages.map { msg in
          ChatMessage(role: msg.role, content: msg.content)
        }
        let model = state.model
        state.inputText = ""
        
        return .run { send in
          do {
            let stream = try await ollamaService.chat(
              model: model,
              messages: currentMessages
            )
            
            for try await response in stream {
              await send(.streamChunk(response))
              
              if response.done == true {
                await send(.streamFinished)
                break
              }
            }
          } catch {
            await send(.errorOccurred(error.localizedDescription))
          }
        }
        
      case .messageReceived(let content):
        if let lastMessage = state.messages.last, lastMessage.role == .assistant {
          state.messages[state.messages.count - 1].content = content
        } else {
          state.messages.append(UIMessage(role: .assistant, content: content))
        }
        return .none
        
      case .streamChunk(let response):
        state.isLoading = false
        if let content = response.message?.content {
          if let lastMessage = state.messages.last, lastMessage.role == .assistant {
            state.messages[state.messages.count - 1].content += content
          } else {
            state.messages.append(UIMessage(role: .assistant, content: content))
          }
        }
        return .none
        
      case .streamFinished:
        state.isLoading = false
        return .none
        
      case .errorOccurred(let error):
        state.isLoading = false
        state.errorMessage = error
        return .none
      }
    }
  }
}

// Dependency injection
extension DependencyValues {
  var ollamaService: OllamaService {
    get { self[OllamaServiceKey.self] }
    set { self[OllamaServiceKey.self] = newValue }
  }
}

private struct OllamaServiceKey: DependencyKey {
  static let liveValue = OllamaService()
}

