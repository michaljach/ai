//
//  lamaApp.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct lamaApp: App {
  var body: some Scene {
    WindowGroup {
      MainView(
        store: Store(initialState: Main.State()) {
          Main()
        }
      )
    }
  }
}
