//
//  MockDependencies.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import Foundation
import ComposableArchitecture

// MARK: - Mock UserDefaultsService

extension UserDefaultsService {
  static var mockWithCustomValues: (String) -> UserDefaultsService {
    return { apiKey in
      var store: [String: Any] = [:]

      return UserDefaultsService(
        getDefaultModel: { store["defaultModel"] as? String ?? "models/gemini-3-flash-preview" },
        setDefaultModel: { value in store["defaultModel"] = value },
        getTemperature: { store["temperature"] as? Double ?? 0.7 },
        setTemperature: { value in store["temperature"] = value },
        getMaxTokens: { store["maxTokens"] as? Int ?? 1024 },
        setMaxTokens: { value in store["maxTokens"] = value },
        getAutoSaveChatsEnabled: { store["autoSaveChatsEnabled"] as? Bool ?? true },
        setAutoSaveChatsEnabled: { value in store["autoSaveChatsEnabled"] = value },
        resetToDefaults: {
          store.removeAll()
        }
      )
    }
  }
}

// MARK: - Test Constants

struct TestConstants {
  static let testModel = "models/gemini-3-flash-preview"
  static let testMessage = "Hello, how are you?"
  static let testResponse = "I'm doing well, thank you for asking!"

  static let availableModels = [
    "models/gemini-3-flash-preview",
    "models/gemini-3-pro",
    "models/gemini-3-ultra"
  ]
}
