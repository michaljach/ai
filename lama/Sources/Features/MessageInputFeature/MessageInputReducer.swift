//
//  MessageInputReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MessageInput {
  @ObservableState
  struct State: Equatable {
    var inputText: String = ""
    var isLoading: Bool = false
    var isBlocked: Bool = false
    var isDisabled: Bool {
      inputText.isEmpty || isLoading || isBlocked
    }
    
    init(inputText: String = "", isLoading: Bool = false, isBlocked: Bool = false) {
      self.inputText = inputText
      self.isLoading = isLoading
      self.isBlocked = isBlocked
    }
  }
  
  enum Action: Equatable {
    case inputTextChanged(String)
    case sendButtonTapped
    case submitButtonTapped
    case stopButtonTapped
    case setBlocked(Bool)
    case delegate(Delegate)
    
    enum Delegate: Equatable {
      case sendMessage
      case stopGeneration
    }
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .inputTextChanged(let text):
        state.inputText = text
        return .none
        
      case .sendButtonTapped:
        guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          return .none
        }
        return .run { send in
          await send(.delegate(.sendMessage))
        }
        
      case .submitButtonTapped:
        guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          return .none
        }
        return .run { send in
          await send(.delegate(.sendMessage))
        }
        
      case .stopButtonTapped:
        return .run { send in
          await send(.delegate(.stopGeneration))
        }
        
      case .setBlocked(let isBlocked):
        state.isBlocked = isBlocked
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

