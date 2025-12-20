//
//  ConfigManager.swift
//  lama
//
//  Created by Michal Jach on 20/12/2025.
//

import Foundation

/// Manages access to configuration values from config.json
struct ConfigManager {
  /// Get the Groq API key from config.json
  static var groqAPIKey: String? {
    guard let url = Bundle.main.url(forResource: "config", withExtension: "json") else {
      print("⚠️ config.json not found in bundle")
      return nil
    }
    
    do {
      let data = try Data(contentsOf: url)
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
      
      if let apiKey = json?["groqAPIKey"] as? String,
         !apiKey.isEmpty,
         !apiKey.contains("YOUR_") {
        return apiKey
      }
    } catch {
      print("⚠️ Error reading config.json: \(error)")
    }
    
    return nil
  }
}
