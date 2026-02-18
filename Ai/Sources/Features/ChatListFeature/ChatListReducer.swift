//
//  ChatListReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatList {
  @Dependency(\.googleAIService) var googleAIService
  @Dependency(\.chatStorageService) var chatStorageService
  @Dependency(\.userDefaultsService) var userDefaultsService

  @Reducer
  enum Path {
    case chat(Chat)
    case settings(Settings)
  }

  @ObservableState
  struct State: Equatable {
    var chats: IdentifiedArrayOf<Chat.State> = []
    var path = StackState<Path.State>()
    var availableModels: [AIModel] = []
    var isLoadingModels = false
    var saveDebounceTask: Task<Void, Never>?
  }

  enum Action {
    case newChatButtonTapped
    case settingsButtonTapped
    case removeEmptyChats
    case initialize
    case loadModels
    case modelsLoaded([AIModel])
    case modelsLoadError(String)
    case deleteChat(Chat.State.ID)
    case selectChat(UUID)
    case chats(IdentifiedActionOf<Chat>)
    case path(StackActionOf<Path>)
    case saveChats
    case saveChatsDebounced
    case loadSavedChats
    case savedChatsLoaded([Chat.State])
    case appWillResignActive
    case appWillTerminate
  }

  private static let saveDebounceInterval: UInt64 = 500_000_000 // 500ms in nanoseconds
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .merge(
          .send(.loadModels),
          .send(.loadSavedChats)
        )
      
      case .loadModels:
        state.isLoadingModels = true
        return .run { send in
          do {
            let models = try await googleAIService.listModels()
            await send(.modelsLoaded(models))
          } catch {
            await send(.modelsLoadError(error.localizedDescription))
          }
        }
      
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        
        // Sync models to all chats in collection
        for index in state.chats.indices {
          state.chats[index].modelPickerState.availableModels = models
        }
        
        // Sync models to chats in path (important for auto-created chat on launch)
        // We need to rebuild the path with updated chat states
        var updatedPath = StackState<Path.State>()
        for pathElement in state.path {
          switch pathElement {
          case var .chat(chat):
            chat.modelPickerState.availableModels = models
            updatedPath.append(.chat(chat))
            
            // Also update the chat in the collection if it exists
            if let chatIndex = state.chats.ids.firstIndex(of: chat.id) {
              state.chats[chatIndex].modelPickerState.availableModels = models
            }
          case .settings(let settings):
            updatedPath.append(.settings(settings))
          }
        }
        state.path = updatedPath
        
        return .none
      
      case .modelsLoadError:
        state.isLoadingModels = false
        return .none
        
      case .path(.element(id: _, action: .chat(.messageInput(.sendButtonTapped)))):
        // Sync chat state back to collection after sending a message
        for pathElement in state.path {
          if case let .chat(chat) = pathElement {
            if state.chats.contains(where: { $0.id == chat.id }) {
              state.chats[id: chat.id] = chat
            }
          }
        }
        return .none

      case .path(.element(id: let id, action: .chat(.modelPicker(.modelSelected(_))))):
        // Keep chat list in sync with model changes from an opened chat
        if case let .chat(chat) = state.path[id: id] {
          if state.chats.contains(where: { $0.id == chat.id }) {
            state.chats[id: chat.id] = chat
          }
        }
        return .send(.saveChatsDebounced)

      case .path(.element(id: let id, action: .chat(.modelSelected(_)))):
        // Keep compatibility with direct model selection actions
        if case let .chat(chat) = state.path[id: id] {
          if state.chats.contains(where: { $0.id == chat.id }) {
            state.chats[id: chat.id] = chat
          }
        }
        return .send(.saveChatsDebounced)
        
      case .path(.element(id: let id, action: .chat(.streamComplete))),
           .path(.element(id: let id, action: .chat(.messageError))),
           .path(.element(id: let id, action: .chat(.stopGeneration))):
        // Sync chat state back to collection when streaming completes, errors, or stops
        if case let .chat(chat) = state.path[id: id] {
          if state.chats.contains(where: { $0.id == chat.id }) {
            state.chats[id: chat.id] = chat
          }
        }
        // Save after streaming completes/errors/stops
        return .send(.saveChatsDebounced)

      case .path(.popFrom(id: let id)):
        // Sync chat state back when popping from navigation
        if case let .chat(chat) = state.path[id: id] {
          if state.chats.contains(where: { $0.id == chat.id }) {
            state.chats[id: chat.id] = chat
          }

          // Remove chat if it has no messages
          if chat.messages.isEmpty {
            state.chats.remove(id: chat.id)
          }
        }
        // Auto-save after navigation change (if enabled) - debounced
        return .send(.saveChatsDebounced)
        
      case .path:
        return .none

      case .removeEmptyChats:
        return .none

      case .deleteChat(let id):
        state.chats.remove(id: id)
        // Also remove from path if it's there
        state.path.removeAll { element in
          if case let .chat(chat) = element {
            return chat.id == id
          }
          return false
        }
        // Auto-save after deleting (if enabled) - debounced
        return .send(.saveChatsDebounced)

      case .newChatButtonTapped:

        // Clean up empty chats before creating new one
        let hadEmptyChats = state.chats.contains { $0.messages.isEmpty }
        state.chats.removeAll { $0.messages.isEmpty }

        let newChatId = UUID()
        var newChatItem = Chat.State(id: newChatId)
        newChatItem.modelPickerState.availableModels = state.availableModels
        // Apply user's default model setting from UserDefaults
        newChatItem.modelPickerState.selectedModel = userDefaultsService.getDefaultModel()
        state.chats.insert(newChatItem, at: 0)

        // Only replace the path, don't append
        state.path.removeAll()
        state.path.append(.chat(newChatItem))

        // Auto-save if we removed empty chats (if enabled) - debounced
        if hadEmptyChats {
          return .send(.saveChatsDebounced)
        }
        return .none

      case .settingsButtonTapped:

        // Clean up empty chats before going to settings
        let hadEmptyChats = state.chats.contains { $0.messages.isEmpty }
        state.chats.removeAll { $0.messages.isEmpty }

        // Replace the path with settings
        state.path.removeAll()
        state.path.append(.settings(Settings.State()))

        // Auto-save if we removed empty chats (if enabled) - debounced
        if hadEmptyChats {
          return .send(.saveChatsDebounced)
        }
        return .none
      
      case .selectChat(let id):
        guard let chat = state.chats[id: id] else { return .none }

        // Clean up OTHER empty chats before selecting this one
        let hadEmptyChats = state.chats.contains { $0.id != id && $0.messages.isEmpty }
        state.chats.removeAll { $0.id != id && $0.messages.isEmpty }

        // Replace the path with selected chat
        state.path.removeAll()
        state.path.append(.chat(chat))

        // Auto-save if we removed empty chats (if enabled) - debounced
        if hadEmptyChats {
          return .send(.saveChatsDebounced)
        }
        return .none

      case .chats:
        // Auto-save chats when they change (if enabled) - debounced
        return .send(.saveChatsDebounced)

      case .saveChats:
        // Immediate save (e.g., for app lifecycle events)
        return .run { [chats = state.chats] _ in
          chatStorageService.saveChats(Array(chats))
        }

      case .saveChatsDebounced:
        // Cancel any existing debounce task
        state.saveDebounceTask?.cancel()
        
        // Create new debounced save task
        let task = Task {
          try? await Task.sleep(nanoseconds: Self.saveDebounceInterval)
          if !Task.isCancelled {
            await Task { @MainActor in
              // This will be handled by the next action
            }.value
          }
        }
        state.saveDebounceTask = task
        
        return .run { [chats = state.chats] _ in
          try? await Task.sleep(nanoseconds: Self.saveDebounceInterval)
          if !Task.isCancelled {
            if userDefaultsService.getAutoSaveChatsEnabled() {
              chatStorageService.saveChats(Array(chats))
            }
          }
        }

      case .loadSavedChats:
        return .run { send in
          let savedChats = chatStorageService.loadChats()
          await send(.savedChatsLoaded(savedChats))
        }

      case .savedChatsLoaded(let savedChats):
        // Add saved chats to the list, avoiding duplicates
        for savedChat in savedChats {
          if !state.chats.contains(where: { $0.id == savedChat.id }) {
            // Update the saved chat with current available models
            var updatedChat = savedChat
            updatedChat.modelPickerState.availableModels = state.availableModels
            state.chats.append(updatedChat)
          }
        }

        // If no chats exist after loading, create a new one
        if state.chats.isEmpty {
          return .send(.newChatButtonTapped)
        }
        return .none
        
      case .appWillResignActive:
        // Save immediately when app goes to background
        return .run { [chats = state.chats] _ in
          if userDefaultsService.getAutoSaveChatsEnabled() {
            chatStorageService.saveChats(Array(chats))
          }
        }
        
      case .appWillTerminate:
        // Save immediately when app terminates
        return .run { [chats = state.chats] _ in
          if userDefaultsService.getAutoSaveChatsEnabled() {
            chatStorageService.saveChats(Array(chats))
          }
        }
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension ChatList.Path.State: Equatable {}
