//
//  ChatService.swift
//  iA
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import Foundation

enum ChatError: LocalizedError {
  case noAPIKey
  case networkError(String)
  case invalidResponse
  case apiError(String)
  
  var errorDescription: String? {
    switch self {
    case .noAPIKey:
      return "No API key configured"
    case .networkError(let message):
      return "Network error: \(message)"
    case .invalidResponse:
      return "Invalid response from API"
    case .apiError(let message):
      return "API error: \(message)"
    }
  }
}

struct ChatService {
  var sendMessage: @Sendable (
    _ messages: [ChatMessage],
    _ model: String,
    _ temperature: Double,
    _ maxTokens: Int
  ) async throws -> String
}

extension ChatService: DependencyKey {
  static let liveValue = Self(
    sendMessage: { messages, model, temperature, maxTokens in
      return try await sendGoogleAIMessage(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens
      )
    }
  )
  
  static let testValue = Self(
    sendMessage: { _, _, _, _ in
      "Test response"
    }
  )
}

extension DependencyValues {
  var chatService: ChatService {
    get { self[ChatService.self] }
    set { self[ChatService.self] = newValue }
  }
}

// MARK: - Google AI Implementation
private func sendGoogleAIMessage(
  messages: [ChatMessage],
  model: String,
  temperature: Double,
  maxTokens: Int
) async throws -> String {
  let apiKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
  guard !apiKey.isEmpty else {
    throw ChatError.noAPIKey
  }
  
  // Model name should NOT have "models/" prefix for the URL
  let apiModel = model.replacingOccurrences(of: "models/", with: "")
  
  let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(apiModel):generateContent?key=\(apiKey)")!
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  
  struct GoogleAIMessage: Codable {
    let role: String
    let parts: [Part]
    
    struct Part: Codable {
      let text: String
    }
  }
  
  struct GoogleAIRequest: Codable {
    let contents: [GoogleAIMessage]
    let generationConfig: GenerationConfig
    
    struct GenerationConfig: Codable {
      let temperature: Double
      let maxOutputTokens: Int
      
      enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "max_output_tokens"
      }
    }
  }
  
  // Convert chat messages to Google AI format
  var googleMessages: [GoogleAIMessage] = []
  for message in messages {
    let googleRole = message.role == "user" ? "user" : "model"
    googleMessages.append(
      GoogleAIMessage(
        role: googleRole,
        parts: [GoogleAIMessage.Part(text: message.content)]
      )
    )
  }
  
  let googleRequest = GoogleAIRequest(
    contents: googleMessages,
    generationConfig: GoogleAIRequest.GenerationConfig(
      temperature: temperature,
      maxOutputTokens: maxTokens
    )
  )
  
  request.httpBody = try JSONEncoder().encode(googleRequest)
  
  // Print debug info
  print("📤 Sending request to: \(url.absoluteString.prefix(80))...")
  print("📝 Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "N/A")")
  
  let (data, response) = try await URLSession.shared.data(for: request)
  
  guard let httpResponse = response as? HTTPURLResponse else {
    throw ChatError.invalidResponse
  }
  
  print("📥 Response status: \(httpResponse.statusCode)")
  
  if httpResponse.statusCode != 200 {
    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
    print("❌ API Error: \(errorMessage)")
    throw ChatError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
  }
  
  // Print raw response for debugging
  let rawResponse = String(data: data, encoding: .utf8) ?? "N/A"
  print("✅ Raw response: \(rawResponse.prefix(200))...")
  
  struct GoogleAIResponse: Codable {
    let candidates: [Candidate]?
    let error: ErrorInfo?
    
    struct ErrorInfo: Codable {
      let code: Int?
      let message: String?
      let status: String?
    }
    
    struct Candidate: Codable {
      let content: Content
      let finishReason: String?
      
      struct Content: Codable {
        let parts: [Part]
        
        struct Part: Codable {
          let text: String?
        }
      }
    }
  }
  
  do {
    let googleResponse = try JSONDecoder().decode(GoogleAIResponse.self, from: data)
    
    // Check for API error in response
    if let error = googleResponse.error {
      let errorMsg = error.message ?? "Unknown error"
      print("🚫 API returned error: \(errorMsg)")
      throw ChatError.apiError(errorMsg)
    }
    
    // Check if we have candidates
    guard let candidates = googleResponse.candidates, !candidates.isEmpty else {
      print("⚠️ No candidates in response")
      throw ChatError.invalidResponse
    }
    
    guard let text = candidates.first?.content.parts.first?.text, !text.isEmpty else {
      print("⚠️ No text content in candidate")
      throw ChatError.invalidResponse
    }
    
    print("✨ Got response: \(text.prefix(100))...")
    return text
  } catch let DecodingError.dataCorrupted(context) {
    print("🔴 Decoding error: \(context.debugDescription)")
    throw ChatError.apiError("Failed to decode response: \(context.debugDescription)")
  } catch let DecodingError.keyNotFound(key, context) {
    print("🔴 Key not found: \(key) - \(context.debugDescription)")
    throw ChatError.apiError("Response missing key: \(key)")
  } catch {
    print("🔴 General decoding error: \(error)")
    throw ChatError.apiError("Decode error: \(error.localizedDescription)")
  }
}
