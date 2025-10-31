//
//  AppReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Main {
  @ObservableState
  struct State: Equatable {
    var home = Home.State()
  }
  
  enum Action {
    case home(Home.Action)
  }
  
  var body: some Reducer<State, Action> {
    Scope(state: \.home, action: \.home) {
      Home()
    }
  }
}

