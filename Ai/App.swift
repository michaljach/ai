//
//  lamaApp.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import SwiftUI
import ComposableArchitecture
import UIKit

@main
struct lamaApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ChatListView(
        store: Store(initialState: ChatList.State()) {
          ChatList()
        }
      )
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  static var sharedStore: StoreOf<ChatList>?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Register for app lifecycle notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillTerminate),
      name: UIApplication.willTerminateNotification,
      object: nil
    )
    
    return true
  }
  
  @objc func appWillResignActive() {
    AppDelegate.sharedStore?.send(.appWillResignActive)
  }
  
  @objc func appWillTerminate() {
    AppDelegate.sharedStore?.send(.appWillTerminate)
  }
}
