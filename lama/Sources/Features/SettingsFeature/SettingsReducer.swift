//
//  SettingsReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Settings {
  @ObservableState
  struct State: Equatable {
    var ollamaEndpoint: String = "http://192.168.68.54:11434"
    var defaultModel: String = "gemma3:4b"
    var temperature: Double = 0.7
    var maxTokens: Int = 2048

    init() {
      // Load from UserDefaults
      if let savedEndpoint = UserDefaults.standard.string(forKey: "ollamaEndpoint") {
        self.ollamaEndpoint = savedEndpoint
      }
      if let savedModel = UserDefaults.standard.string(forKey: "defaultModel") {
        self.defaultModel = savedModel
      }
      self.temperature = UserDefaults.standard.double(forKey: "temperature")
      if self.temperature == 0 {
        self.temperature = 0.7
      }
      let savedMaxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
      if savedMaxTokens > 0 {
        self.maxTokens = savedMaxTokens
      }
    }
  }

  enum Action {
    case ollamaEndpointChanged(String)
    case defaultModelChanged(String)
    case temperatureChanged(Double)
    case maxTokensChanged(Int)
    case resetToDefaults
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .ollamaEndpointChanged(let value):
        state.ollamaEndpoint = value
        UserDefaults.standard.set(value, forKey: "ollamaEndpoint")
        return .none

      case .defaultModelChanged(let value):
        state.defaultModel = value
        UserDefaults.standard.set(value, forKey: "defaultModel")
        return .none

      case .temperatureChanged(let value):
        state.temperature = value
        UserDefaults.standard.set(value, forKey: "temperature")
        return .none

      case .maxTokensChanged(let value):
        state.maxTokens = value
        UserDefaults.standard.set(value, forKey: "maxTokens")
        return .none

      case .resetToDefaults:
        state.ollamaEndpoint = "http://192.168.68.54:11434"
        state.defaultModel = "gemma3:4b"
        state.temperature = 0.7
        state.maxTokens = 2048
        UserDefaults.standard.set(state.ollamaEndpoint, forKey: "ollamaEndpoint")
        UserDefaults.standard.set(state.defaultModel, forKey: "defaultModel")
        UserDefaults.standard.set(state.temperature, forKey: "temperature")
        UserDefaults.standard.set(state.maxTokens, forKey: "maxTokens")
        return .none
      }
    }
  }
}
