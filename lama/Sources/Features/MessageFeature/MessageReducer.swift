//
//  MessageReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Message {
  @ObservableState
  struct State: Equatable, Identifiable {
    var id: UUID
    var role: MessageRole
    var content: String
    
    init(id: UUID = UUID(), role: MessageRole, content: String) {
      self.id = id
      self.role = role
      self.content = content
    }
  }
  
  enum Action: Equatable {
    
  }
  
  var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}
