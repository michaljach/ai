//
//  AppView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct MainView: View {
  var store: StoreOf<Main>
  
  var body: some View {
    HomeView(store: store.scope(state: \.home, action: \.home))
  }
}

#Preview {
  MainView(
    store: Store(initialState: Main.State()) {
      Main()
    }
  )
}

