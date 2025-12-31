//
//  MockDependencies.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import Foundation
import ComposableArchitecture

// MARK: - Mock GroqService

extension GroqService {
  static let testValue = GroqService()
  
  static var mockStreamingChat: GroqService {
    let mockService = GroqService()
    return mockService
  }
}

// MARK: - Mock UserDefaultsService

extension UserDefaultsService {
  static var mockWithCustomValues: (String) -> UserDefaultsService {
    return { apiKey in
      var store: [String: Any] = [:]
      
      return UserDefaultsService(
        getGroqAPIKey: { store["groqAPIKey"] as? String },
        setGroqAPIKey: { value in store["groqAPIKey"] = value },
        getDefaultModel: { store["defaultModel"] as? String ?? "groq/compound" },
        setDefaultModel: { value in store["defaultModel"] = value },
        getTemperature: { store["temperature"] as? Double ?? 0.7 },
        setTemperature: { value in store["temperature"] = value },
        getMaxTokens: { store["maxTokens"] as? Int ?? 640 },
        setMaxTokens: { value in store["maxTokens"] = value },
        isWebSearchEnabled: { store["webSearchEnabled"] as? Bool ?? true },
        setWebSearchEnabled: { value in store["webSearchEnabled"] = value },
        resetToDefaults: {
          store.removeAll()
        }
      )
    }
  }
}

// MARK: - Test Constants

struct TestConstants {
  static let testAPIKey = "test-api-key-12345"
  static let testModel = "mixtral-8x7b-32768"
  static let testMessage = "Hello, how are you?"
  static let testResponse = "I'm doing well, thank you for asking!"
  
  static let availableModels = [
    "mixtral-8x7b-32768",
    "llama-2-70b-chat",
    "groq/compound",
    "qwen/qwen3-70b-32k",
    "gpt-oss-3.5-turbo"
  ]
}
