//
//  IntegrationTests.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import XCTest
import Foundation

final class GroqModelsIntegrationTests: XCTestCase {
  
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  
  func test_complexChatMessage_roundTrip() throws {
    // Create a realistic chat message with images and text
    let blocks = [
      ContentBlock(type: "text", text: "Analyze this image:"),
      ContentBlock(type: "image_url", imageUrl: "https://example.com/image.jpg")
    ]
    
    let message = ChatMessage(
      role: .user,
      content: .array(blocks)
    )
    
    let data = try encoder.encode(message)
    let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
    
    XCTAssertEqual(decodedMessage.role, message.role)
  }
  
  func test_groqChatRequest_withReasoningAndWebSearch() throws {
    let messages = [
      ChatMessage(role: .system, content: "You are helpful"),
      ChatMessage(role: .user, content: "What's the weather?")
    ]
    
    let request = GroqChatRequest(
      model: "gpt-oss-3.5-turbo",
      messages: messages,
      temperature: 0.5,
      maxTokens: 2048,
      topP: 0.95,
      stream: true,
      includeReasoning: true,
      reasoningEffort: "medium"
    )
    
    let data = try encoder.encode(request)
    XCTAssertGreater(data.count, 0)
    
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["include_reasoning"] as? Bool, true)
    XCTAssertEqual(json?["reasoning_effort"] as? String, "medium")
  }
  
  func test_multipleMessagesWithDifferentContentTypes() throws {
    let messages = [
      ChatMessage(role: .system, content: "You are a helpful assistant"),
      ChatMessage(role: .user, content: "Hello"),
      ChatMessage(role: .assistant, content: "Hi there!"),
      ChatMessage(role: .user, content: "What's your name?")
    ]
    
    for message in messages {
      let data = try encoder.encode(message)
      let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
      
      XCTAssertEqual(decodedMessage.role, message.role)
      if case .text(let originalText) = message.content,
         case .text(let decodedText) = decodedMessage.content {
        XCTAssertEqual(decodedText, originalText)
      }
    }
  }
  
  func test_messageContent_withSpecialCharacters() throws {
    let specialContent = "Hello! This is a test with special chars: @#$%^&*()_+-=[]{}|;:',.<>?/~`"
    let message = ChatMessage(role: .user, content: specialContent)
    
    let data = try encoder.encode(message)
    let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
    
    if case .text(let text) = decodedMessage.content {
      XCTAssertEqual(text, specialContent)
    } else {
      XCTFail("Expected text content")
    }
  }
  
  func test_contentBlock_withEmptyText() throws {
    let block = ContentBlock(type: "text", text: "")
    
    let data = try encoder.encode(block)
    let decodedBlock = try decoder.decode(ContentBlock.self, from: data)
    
    XCTAssertEqual(decodedBlock.text, "")
    XCTAssertEqual(decodedBlock.type, "text")
  }
  
  func test_imageUrl_withValidURL() throws {
    let urls = [
      "https://example.com/image.jpg",
      "https://cdn.example.com/images/photo-123.png",
      "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
      "file:///Users/example/image.jpg"
    ]
    
    for urlString in urls {
      let imageUrl = ImageUrl(url: urlString)
      let data = try encoder.encode(imageUrl)
      let decodedUrl = try decoder.decode(ImageUrl.self, from: data)
      
      XCTAssertEqual(decodedUrl.url, urlString)
    }
  }
}

final class JSONEncodingEdgeCaseTests: XCTestCase {
  
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  
  func test_veryLongMessage() throws {
    let longText = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 100)
    let message = ChatMessage(role: .user, content: longText)
    
    let data = try encoder.encode(message)
    let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
    
    if case .text(let text) = decodedMessage.content {
      XCTAssertEqual(text, longText)
    } else {
      XCTFail("Expected text content")
    }
  }
  
  func test_messageWithUnicodeCharacters() throws {
    let unicodeContent = "Hello 你好 مرحبا שלום Здравствуй 🚀🎉"
    let message = ChatMessage(role: .user, content: unicodeContent)
    
    let data = try encoder.encode(message)
    let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
    
    if case .text(let text) = decodedMessage.content {
      XCTAssertEqual(text, unicodeContent)
    } else {
      XCTFail("Expected text content")
    }
  }
  
  func test_groqRequestWithMinimalData() throws {
    let message = ChatMessage(role: .user, content: "Hi")
    let request = GroqChatRequest(
      model: "test",
      messages: [message],
      stream: false
    )
    
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertNotNil(json?["model"])
    XCTAssertNotNil(json?["messages"])
    XCTAssertNotNil(json?["stream"])
  }
  
  func test_groqRequestWithMaximalData() throws {
    let blocks = [
      ContentBlock(type: "text", text: "Check this:"),
      ContentBlock(type: "image_url", imageUrl: "https://example.com/img.jpg")
    ]
    
    let message = ChatMessage(role: .user, content: .array(blocks))
    let request = GroqChatRequest(
      model: "gpt-oss-3.5-turbo",
      messages: [message],
      temperature: 0.9,
      maxTokens: 4096,
      topP: 0.99,
      stream: true,
      includeReasoning: true,
      reasoningEffort: "high"
    )
    
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["temperature"] as? Double, 0.9)
    XCTAssertEqual(json?["max_tokens"] as? Int, 4096)
    XCTAssertEqual(json?["top_p"] as? Double, 0.99)
    XCTAssertEqual(json?["stream"] as? Bool, true)
    XCTAssertEqual(json?["include_reasoning"] as? Bool, true)
    XCTAssertEqual(json?["reasoning_effort"] as? String, "high")
  }
}
