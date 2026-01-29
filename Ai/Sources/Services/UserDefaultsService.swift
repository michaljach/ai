//
//  UserDefaultsService.swift
//  lama
//
//  Created by Michal Jach on 10/11/2025.
//

import Foundation
import ComposableArchitecture

/// Service for managing user defaults/preferences
struct UserDefaultsService {
  // Keys
  private enum Keys {
    static let defaultModel = "defaultModel"
    static let temperature = "temperature"
    static let maxTokens = "maxTokens"
    static let autoSaveChatsEnabled = "autoSaveChatsEnabled"
  }

  // Default values
  private enum Defaults {
    nonisolated static let defaultModel = "models/gemini-3-flash-preview"
    nonisolated static let temperature = 0.7
    nonisolated static let maxTokens = 1024
    nonisolated static let autoSaveChatsEnabled = true
  }
  
  var getDefaultModel: @Sendable () -> String
  var setDefaultModel: @Sendable (String) -> Void
  
  var getTemperature: @Sendable () -> Double
  var setTemperature: @Sendable (Double) -> Void
  
  var getMaxTokens: @Sendable () -> Int
  var setMaxTokens: @Sendable (Int) -> Void

  var getAutoSaveChatsEnabled: @Sendable () -> Bool
  var setAutoSaveChatsEnabled: @Sendable (Bool) -> Void

  var resetToDefaults: @Sendable () -> Void
}

extension UserDefaultsService: DependencyKey {
  static let liveValue = UserDefaultsService(
    getDefaultModel: {
      UserDefaults.standard.string(forKey: Keys.defaultModel) ?? Defaults.defaultModel
    },
    setDefaultModel: { value in
      UserDefaults.standard.set(value, forKey: Keys.defaultModel)
    },
    getTemperature: {
      let value = UserDefaults.standard.double(forKey: Keys.temperature)
      return value == 0 ? Defaults.temperature : value
    },
    setTemperature: { value in
      UserDefaults.standard.set(value, forKey: Keys.temperature)
    },
    getMaxTokens: {
      let value = UserDefaults.standard.integer(forKey: Keys.maxTokens)
      return value > 0 ? value : Defaults.maxTokens
    },
    setMaxTokens: { value in
      UserDefaults.standard.set(value, forKey: Keys.maxTokens)
    },
    getAutoSaveChatsEnabled: {
      UserDefaults.standard.object(forKey: Keys.autoSaveChatsEnabled) != nil
        ? UserDefaults.standard.bool(forKey: Keys.autoSaveChatsEnabled)
        : Defaults.autoSaveChatsEnabled
    },
    setAutoSaveChatsEnabled: { value in
      UserDefaults.standard.set(value, forKey: Keys.autoSaveChatsEnabled)
    },
    resetToDefaults: {
      UserDefaults.standard.set(Defaults.defaultModel, forKey: Keys.defaultModel)
      UserDefaults.standard.set(Defaults.temperature, forKey: Keys.temperature)
      UserDefaults.standard.set(Defaults.maxTokens, forKey: Keys.maxTokens)
      UserDefaults.standard.set(Defaults.autoSaveChatsEnabled, forKey: Keys.autoSaveChatsEnabled)
    }
  )

  static let testValue = UserDefaultsService(
    getDefaultModel: { Defaults.defaultModel },
    setDefaultModel: { _ in },
    getTemperature: { Defaults.temperature },
    setTemperature: { _ in },
    getMaxTokens: { Defaults.maxTokens },
    setMaxTokens: { _ in },
    getAutoSaveChatsEnabled: { Defaults.autoSaveChatsEnabled },
    setAutoSaveChatsEnabled: { _ in },
    resetToDefaults: { }
  )
}

extension DependencyValues {
  var userDefaultsService: UserDefaultsService {
    get { self[UserDefaultsService.self] }
    set { self[UserDefaultsService.self] = newValue }
  }
}

