//
//  ChatListItemFeature.swift
//  lama
//
//  Created by Michal Jach on 01/11/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatListItem {
  @ObservableState
  struct State: Equatable, Identifiable {
    var id: UUID
  }
  
  enum Action: Equatable {
    
  }
  
  var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}
