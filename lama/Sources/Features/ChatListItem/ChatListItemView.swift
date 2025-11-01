//
//  ChatListItemView.swift
//  lama
//
//  Created by Michal Jach on 01/11/2025.
//

import ComposableArchitecture
import SwiftUI

struct ChatListItemView: View {
  var store: StoreOf<ChatListItem>
  
  var body: some View {
    Text("Item")
  }
}

#Preview {
  ChatListItemView(
    store: Store(initialState: ChatListItem.State(
      id: UUID()
    )) {
      ChatListItem()
    }
  )
}
