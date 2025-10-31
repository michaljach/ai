//
//  OllamaModels.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import Foundation

// MARK: - Request Models

struct ChatRequest: Codable {
  let model: String
  let messages: [ChatMessage]
  let stream: Bool
  let options: ChatOptions?
  
  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case stream
    case options
  }
}

struct GenerateRequest: Codable {
  let model: String
  let prompt: String
  let stream: Bool
  let options: GenerateOptions?
  
  enum CodingKeys: String, CodingKey {
    case model
    case prompt
    case stream
    case options
  }
}

struct ShowModelRequest: Codable {
  let name: String
}

struct EmptyRequest: Codable {}

// MARK: - Response Models

struct ChatResponse: Codable {
  let model: String?
  let createdAt: String?
  let message: ChatMessage?
  let done: Bool?
  let totalDuration: Int64?
  let loadDuration: Int64?
  let promptEvalCount: Int?
  let promptEvalDuration: Int64?
  let evalCount: Int?
  let evalDuration: Int64?
  
  enum CodingKeys: String, CodingKey {
    case model
    case createdAt = "created_at"
    case message
    case done
    case totalDuration = "total_duration"
    case loadDuration = "load_duration"
    case promptEvalCount = "prompt_eval_count"
    case promptEvalDuration = "prompt_eval_duration"
    case evalCount = "eval_count"
    case evalDuration = "eval_duration"
  }
}

struct GenerateResponse: Codable {
  let model: String?
  let createdAt: String?
  let response: String?
  let done: Bool?
  let totalDuration: Int64?
  let loadDuration: Int64?
  let promptEvalCount: Int?
  let promptEvalDuration: Int64?
  let evalCount: Int?
  let evalDuration: Int64?
  
  enum CodingKeys: String, CodingKey {
    case model
    case createdAt = "created_at"
    case response
    case done
    case totalDuration = "total_duration"
    case loadDuration = "load_duration"
    case promptEvalCount = "prompt_eval_count"
    case promptEvalDuration = "prompt_eval_duration"
    case evalCount = "eval_count"
    case evalDuration = "eval_duration"
  }
}

struct ListModelsResponse: Codable {
  let models: [ModelInfo]
}

struct ShowModelResponse: Codable {
  let modelfile: String
  let parameters: String
  let template: String
  let details: ModelDetails
  let system: String?
  let license: String?
}

struct ModelInfo: Codable {
  let name: String
  let modifiedAt: String
  let size: Int64
  let digest: String
  let details: ModelDetails?
  
  enum CodingKeys: String, CodingKey {
    case name
    case modifiedAt = "modified_at"
    case size
    case digest
    case details
  }
}

struct ModelDetails: Codable {
  let parentModel: String?
  let format: String?
  let family: String?
  let parameterSize: String?
  let quantizationLevel: String?
  
  enum CodingKeys: String, CodingKey {
    case parentModel = "parent_model"
    case format
    case family
    case parameterSize = "parameter_size"
    case quantizationLevel = "quantization_level"
  }
}

struct ChatMessage: Codable {
  let role: MessageRole
  let content: String
}

enum MessageRole: String, Codable {
  case system
  case user
  case assistant
}

// MARK: - Options

struct ChatOptions: Codable {
  let temperature: Double?
  let topP: Double?
  let topK: Int?
  let repeatPenalty: Double?
  let seed: Int?
  
  enum CodingKeys: String, CodingKey {
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case repeatPenalty = "repeat_penalty"
    case seed
  }
  
  init(
    temperature: Double? = nil,
    topP: Double? = nil,
    topK: Int? = nil,
    repeatPenalty: Double? = nil,
    seed: Int? = nil
  ) {
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.repeatPenalty = repeatPenalty
    self.seed = seed
  }
}

struct GenerateOptions: Codable {
  let temperature: Double?
  let topP: Double?
  let topK: Int?
  let repeatPenalty: Double?
  let seed: Int?
  
  enum CodingKeys: String, CodingKey {
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case repeatPenalty = "repeat_penalty"
    case seed
  }
  
  init(
    temperature: Double? = nil,
    topP: Double? = nil,
    topK: Int? = nil,
    repeatPenalty: Double? = nil,
    seed: Int? = nil
  ) {
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.repeatPenalty = repeatPenalty
    self.seed = seed
  }
}

// MARK: - Error Models

struct OllamaErrorResponse: Codable {
  let error: String
}

// MARK: - Errors

enum OllamaError: LocalizedError {
  case invalidURL
  case encodingError(Error)
  case decodingError(Error)
  case networkError(Error)
  case invalidResponse
  case httpError(Int)
  case apiError(String)
  
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .encodingError(let error):
      return "Encoding error: \(error.localizedDescription)"
    case .decodingError(let error):
      return "Decoding error: \(error.localizedDescription)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid response"
    case .httpError(let code):
      return "HTTP error: \(code)"
    case .apiError(let message):
      return "API error: \(message)"
    }
  }
}

