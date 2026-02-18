//
//  ChatStorageService.swift
//  lama
//
//  Created by Assistant on 29/01/2026.
//

import Foundation
import ComposableArchitecture
import UIKit

/// Service for persisting chats to local device storage
struct ChatStorageService {
  private static let chatsDirectoryName = "SavedChats"
  private static let chatsFileName = "chats.json"

  var saveChats: @Sendable ([Chat.State]) -> Void
  var loadChats: @Sendable () -> [Chat.State]
  var deleteAllChats: @Sendable () -> Void

  /// Codable representation of a chat for storage
  private struct StoredChat: Codable {
    let id: UUID
    let model: String
    let messages: [StoredMessage]
    let createdAt: Date

    struct StoredMessage: Codable {
      let id: UUID
      let role: MessageRole
      let content: String
      let sources: [WebSource]

      enum MessageRole: String, Codable {
        case user
        case assistant
      }
    }
  }

  /// Converts Chat.State to StoredChat
  private static func toStoredChat(_ chat: Chat.State) -> StoredChat {
    StoredChat(
      id: chat.id,
      model: chat.modelPickerState.selectedModel,
      messages: chat.messages.map { message in
        StoredChat.StoredMessage(
          id: message.id,
          role: message.role == .user ? .user : .assistant,
          content: message.content,
          sources: message.sources
        )
      },
      createdAt: Date()
    )
  }

  /// Converts StoredChat back to Chat.State
  private static func fromStoredChat(_ stored: StoredChat, availableModels: [AIModel]) -> Chat.State {
    var chatState = Chat.State(id: stored.id)
    chatState.model = stored.model
    chatState.modelPickerState.selectedModel = stored.model
    chatState.modelPickerState.availableModels = availableModels

    for storedMessage in stored.messages {
      let messageState = Message.State(
        id: storedMessage.id,
        role: storedMessage.role == .user ? .user : .assistant,
        content: storedMessage.content,
        sources: storedMessage.sources
      )
      chatState.messages.append(messageState)
    }

    return chatState
  }

  /// Gets the URL for the chats directory
  private static func getChatsDirectory() -> URL? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }
    let chatsDirectory = documentsDirectory.appendingPathComponent(chatsDirectoryName)

    // Create directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: chatsDirectory.path) {
      try? FileManager.default.createDirectory(at: chatsDirectory, withIntermediateDirectories: true)
    }

    return chatsDirectory
  }

  /// Gets the URL for the chats file
  private static func getChatsFileURL() -> URL? {
    getChatsDirectory()?.appendingPathComponent(chatsFileName)
  }
}

extension ChatStorageService: DependencyKey {
  static let liveValue = ChatStorageService(
    saveChats: { chats in
      guard let fileURL = getChatsFileURL() else { return }

      // Filter out empty chats
      let nonEmptyChats = chats.filter { !$0.messages.isEmpty }

      // Convert to stored format
      let storedChats = nonEmptyChats.map { toStoredChat($0) }

      // Encode and save
      do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(storedChats)
        try data.write(to: fileURL, options: .atomic)
      } catch {
        print("Failed to save chats: \(error)")
      }
    },
    loadChats: {
      guard let fileURL = getChatsFileURL(),
            FileManager.default.fileExists(atPath: fileURL.path) else {
        return []
      }

      do {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let storedChats = try decoder.decode([StoredChat].self, from: data)

        // Get available models from UserDefaults
        let defaultModel = UserDefaults.standard.string(forKey: "defaultModel") ?? "models/gemini-3-flash-preview"

        // Convert back to Chat.State
        return storedChats.map { fromStoredChat($0, availableModels: []) }
      } catch {
        print("Failed to load chats: \(error)")
        return []
      }
    },
    deleteAllChats: {
      guard let fileURL = getChatsFileURL() else { return }
      try? FileManager.default.removeItem(at: fileURL)
    }
  )

  static let testValue = ChatStorageService(
    saveChats: { _ in },
    loadChats: { [] },
    deleteAllChats: { }
  )
}

extension DependencyValues {
  var chatStorageService: ChatStorageService {
    get { self[ChatStorageService.self] }
    set { self[ChatStorageService.self] = newValue }
  }
}
