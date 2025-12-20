//
//  ChatReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct Chat {
  @Dependency(\.groqService) var groqService
  @Dependency(\.userDefaultsService) var userDefaultsService
  
  nonisolated enum CancelID: Hashable, Sendable {
    case streaming
  }
  
  enum LoadingState: Equatable {
    case idle
    case loading
  }
  
  @ObservableState
  struct State: Equatable, Identifiable {
    let id: UUID
    var model: String
    var availableModels: [String] = []
    var isLoadingModels: Bool = false
    var errorMessage: String?
    var loadingState: LoadingState = .idle
    var messages: IdentifiedArrayOf<Message.State> = []
    var visibleMessages: IdentifiedArrayOf<Message.State> {
      self.messages.filter({ [.assistant, .system, .user].contains($0.role) })
    }
    var messageInputState = MessageInput.State()
    var scrollPosition: String?
    
    init(id: UUID, userDefaultsService: UserDefaultsService = .liveValue) {
      self.id = id
      // Load default model from settings
      self.model = userDefaultsService.getDefaultModel()
    }
    
    /// Computed property for chat title based on first user message
    var title: String {
      // Find the first user message
      if let firstUserMessage = messages.first(where: { $0.role == .user }) {
        let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        // Limit to first 50 characters
        if content.count > 50 {
          return String(content.prefix(50)) + "..."
        }
        return content.isEmpty ? "New Chat" : content
      }
      return "New Chat"
    }
  }
  
  enum Action {
    case messages(IdentifiedActionOf<Message>)
    case messageInput(MessageInput.Action)
    case onAppear
    case onDisappear
    case modelSelected(String)
    case loadModels
    case modelsLoaded([String])
    case modelsLoadError(String)
    case startChatStream([ChatMessage], enableWebSearch: Bool = true)
    case streamingResponseReceived(String)
    case streamingComplete(reason: String?)
    case streamingError(String)
    case stopGeneration
    case scrollPositionChanged(String?)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { (state: inout State, action: Action) -> Effect<Action> in
      switch action {
      case .onAppear:
        return .send(.loadModels)
        
      case .onDisappear:
        // Stop generation when navigating away
        if state.loadingState != .idle {
          return .send(.stopGeneration)
        }
        return .none
        
      case .loadModels:
        state.isLoadingModels = true
        return .run { send in
          do {
            let models = try await groqService.listModels()
            await send(.modelsLoaded(models))
          } catch {
            await send(.modelsLoadError(error.localizedDescription))
          }
        }
        
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        // If current model is not in the list and there are models, select the first one
        if !models.isEmpty && !models.contains(state.model) {
          state.model = models[0]
        }
        return .none
        
      case .modelsLoadError:
        state.isLoadingModels = false
        // Silently fail - keep the default model
        return .none
        
      case .modelSelected(let model):
        state.model = model
        return .none
        
      case .messageInput(.delegate(.sendMessage)):
        let inputText = state.messageInputState.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedImages = state.messageInputState.selectedImages
        let hasImages = !selectedImages.isEmpty
        
        guard !inputText.isEmpty || hasImages else {
          return .none
        }
        
        // Clear input and show loading
        state.messageInputState.inputText = ""
        state.messageInputState.selectedImages = []
        state.messageInputState.isLoading = true
        state.errorMessage = nil
        state.loadingState = .loading
        
        // Add user message with images
        let userMessageId = UUID()
        let userMessage = Message.State(
          id: userMessageId,
          role: .user,
          content: inputText,
          images: selectedImages
        )
        state.messages.append(userMessage)

        // Build messages for API - construct special multimodal format only for current user message with images
        var chatMessages: [ChatMessage] = []
        
        for message in state.messages {
          if message.id == userMessageId && hasImages && !selectedImages.isEmpty {
            // Build multimodal content block array for this user message
            var contentBlocks: [ContentBlock] = []
            
            // Add text block if there's text
            if !inputText.isEmpty {
              contentBlocks.append(ContentBlock(type: "text", text: inputText))
            }
            
            // Add image blocks in proper OpenAI format
            for image in selectedImages {
              // Resize and compress image to reduce request size
              let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))
              if let imageData = resizedImage.jpegData(compressionQuality: 0.6) {
                let base64String = imageData.base64EncodedString()
                let dataUrl = "data:image/jpeg;base64,\(base64String)"
                contentBlocks.append(ContentBlock(type: "image_url", imageUrl: dataUrl))
              }
            }
            
            chatMessages.append(ChatMessage(role: message.role, content: .array(contentBlocks)))
          } else {
            // All other messages (including previous turns) must be text-only
            chatMessages.append(ChatMessage(role: message.role, content: .text(message.content)))
          }
        }
        
        chatMessages = chatMessages.withDefaultSystemPrompt()

        // Force a new scroll event by clearing, then sending an update
        state.scrollPosition = nil
        
        return .merge(
          .send(.scrollPositionChanged("bottom")),
          .send(.startChatStream(chatMessages))
        )
        
      case .startChatStream(let chatMessages, let enableWebSearch):
        let temperature = userDefaultsService.getTemperature()
        let maxTokens = userDefaultsService.getMaxTokens()
        
        return .run { [model = state.model] send in
          do {
            let stream = try await groqService.chat(
              model: model,
              messages: chatMessages,
              temperature: temperature,
              maxTokens: maxTokens,
              topP: nil,
              enableWebSearch: enableWebSearch
            )
            
            for try await response in stream {
              if Task.isCancelled {
                await send(.streamingComplete(reason: nil))
                break
              }
              
              // Extract content from the response
              if let message = response.message {
                var contentText = ""
                if case .text(let text) = message.content {
                  contentText = text
                }
                if !contentText.isEmpty {
                  await send(.streamingResponseReceived(contentText))
                }
              }
              
              if response.done ?? false {
                await send(.streamingComplete(reason: response.doneReason))
              }
            }
          } catch {
            await send(.streamingError(error.localizedDescription))
          }
        }
        .cancellable(id: CancelID.streaming, cancelInFlight: true)
        
      case .streamingResponseReceived(let content):
        state.errorMessage = nil
        
        // Create assistant message if it doesn't exist, otherwise append to it
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          // Append to existing assistant message
          state.messages[lastIndex].content += content
        } else {
          // Create new assistant message with this content
          let assistantMessage = Message.State(
            id: UUID(),
            role: .assistant,
            content: content
          )
          state.messages.append(assistantMessage)
        }

        return .none
        
      case .streamingComplete(let reason):
        state.loadingState = .idle
        state.messageInputState.isLoading = false

        state.scrollPosition = nil
        return .send(.scrollPositionChanged("bottom"))
        
      case .streamingError(let errorMessage):
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        state.errorMessage = errorMessage
        return .none
        
      case .stopGeneration:
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        return .cancel(id: CancelID.streaming)
        
      case .messageInput(.delegate(.stopGeneration)):
        return .send(.stopGeneration)
        
      case .messageInput:
        // Forward all other messageInput actions to the child reducer
        return .none
        
      case .messages:
        return .none
        
      case .scrollPositionChanged(let position):
        state.scrollPosition = position
        return .none
      }
    }
    Scope(state: \.messageInputState, action: \.messageInput) {
      MessageInput()
    }
  }
}

// MARK: - UIImage Extension

extension UIImage {
  /// Resize image to fit within the specified size while maintaining aspect ratio
  func resized(to size: CGSize) -> UIImage {
    let aspectRatio = self.size.width / self.size.height
    let targetSize: CGSize
    
    if aspectRatio > 1 {
      // Landscape or square
      targetSize = CGSize(width: size.width, height: size.width / aspectRatio)
    } else {
      // Portrait
      targetSize = CGSize(width: size.height * aspectRatio, height: size.height)
    }
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    
    return resizedImage
  }
}
