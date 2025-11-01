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
  @Reducer
  enum Path {
    case chat(Chat)
  }
  
  @ObservableState
  struct State: Equatable {
    var chats: IdentifiedArrayOf<ChatListItem.State> = [ChatListItem.State(id: UUID())]
    var path = StackState<Path.State>()
  }
  
  enum Action {
    case newChatButtonTapped
    case chats(IdentifiedActionOf<ChatListItem>)
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .path(action):
        switch action {
        default:
          return .none
        }
        
      case .newChatButtonTapped:
        return .none
        
      case .chats:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension ChatList.Path.State: Equatable {}
