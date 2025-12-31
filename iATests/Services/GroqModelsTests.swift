//
//  GroqModelsTests.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import XCTest
import Foundation

final class GroqModelsTests: XCTestCase {
  
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  
  // MARK: - ChatMessage Tests
  
  func test_chatMessage_withTextContent_encodesCorrectly() throws {
    let message = ChatMessage(role: .user, content: "Hello, world!")
    
    let data = try encoder.encode(message)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["role"] as? String, "user")
    XCTAssertEqual(json?["content"] as? String, "Hello, world!")
  }
  
  func test_chatMessage_withArrayContent_encodesCorrectly() throws {
    let blocks = [
      ContentBlock(type: "text", text: "Check this image:", image_url: nil),
      ContentBlock(type: "image_url", text: nil, image_url: ImageUrl(url: "https://example.com/image.jpg"))
    ]
    let message = ChatMessage(role: .user, content: .array(blocks))
    
    let data = try encoder.encode(message)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["role"] as? String, "user")
    XCTAssertIsNotNil(json?["content"] as? [[String: Any]])
  }
  
  func test_chatMessage_decodesFromJSON() throws {
    let jsonString = """
    {
      "role": "assistant",
      "content": "This is a response"
    }
    """
    
    let data = jsonString.data(using: .utf8)!
    let message = try decoder.decode(ChatMessage.self, from: data)
    
    XCTAssertEqual(message.role, .assistant)
    if case .text(let text) = message.content {
      XCTAssertEqual(text, "This is a response")
    } else {
      XCTFail("Expected text content")
    }
  }
  
  func test_chatMessage_withDifferentRoles() throws {
    let roles: [MessageRole] = [.system, .user, .assistant]
    
    for role in roles {
      let message = ChatMessage(role: role, content: "Test")
      let data = try encoder.encode(message)
      let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
      
      XCTAssertEqual(decodedMessage.role, role)
    }
  }
  
  // MARK: - ContentBlock Tests
  
  func test_contentBlock_text_createsCorrectly() {
    let block = ContentBlock(type: "text", text: "Hello")
    
    XCTAssertEqual(block.type, "text")
    XCTAssertEqual(block.text, "Hello")
    XCTAssertNil(block.image_url)
  }
  
  func test_contentBlock_imageUrl_createsCorrectly() {
    let block = ContentBlock(type: "image_url", imageUrl: "https://example.com/image.jpg")
    
    XCTAssertEqual(block.type, "image_url")
    XCTAssertNil(block.text)
    XCTAssertEqual(block.image_url?.url, "https://example.com/image.jpg")
  }
  
  func test_contentBlock_encodesAndDecodes() throws {
    let block = ContentBlock(type: "text", text: "Test content")
    
    let data = try encoder.encode(block)
    let decodedBlock = try decoder.decode(ContentBlock.self, from: data)
    
    XCTAssertEqual(decodedBlock.type, block.type)
    XCTAssertEqual(decodedBlock.text, block.text)
  }
  
  // MARK: - GroqChatRequest Tests
  
  func test_groqChatRequest_encodesWithAllFields() throws {
    let messages = [
      ChatMessage(role: .system, content: "You are helpful"),
      ChatMessage(role: .user, content: "Hello")
    ]
    
    let request = GroqChatRequest(
      model: "mixtral-8x7b-32768",
      messages: messages,
      temperature: 0.7,
      maxTokens: 1024,
      topP: 0.9,
      stream: true,
      includeReasoning: false,
      reasoningEffort: "low"
    )
    
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["model"] as? String, "mixtral-8x7b-32768")
    XCTAssertEqual(json?["temperature"] as? Double, 0.7)
    XCTAssertEqual(json?["max_tokens"] as? Int, 1024)
    XCTAssertEqual(json?["top_p"] as? Double, 0.9)
    XCTAssertEqual(json?["stream"] as? Bool, true)
  }
  
  func test_groqChatRequest_encodesWithNilOptionalFields() throws {
    let messages = [ChatMessage(role: .user, content: "Hello")]
    
    let request = GroqChatRequest(
      model: "mixtral-8x7b-32768",
      messages: messages,
      temperature: nil,
      maxTokens: nil,
      topP: nil,
      stream: false
    )
    
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["model"] as? String, "mixtral-8x7b-32768")
    XCTAssertEqual(json?["stream"] as? Bool, false)
    // nil values should not be encoded
    XCTAssertNil(json?["temperature"])
  }
  
  func test_groqChatRequest_withStream_isCorrect() throws {
    let messages = [ChatMessage(role: .user, content: "Test")]
    
    let streamingRequest = GroqChatRequest(
      model: "mixtral",
      messages: messages,
      stream: true
    )
    
    let data = try encoder.encode(streamingRequest)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    
    XCTAssertEqual(json?["stream"] as? Bool, true)
  }
  
  // MARK: - MessageContent Tests
  
  func test_messageContent_text_encodesAsString() throws {
    let content = MessageContent.text("Hello world")
    
    let data = try encoder.encode(content)
    let string = String(data: data, encoding: .utf8)
    
    XCTAssertTrue(string?.contains("Hello world") ?? false)
  }
  
  func test_messageContent_array_encodesAsArray() throws {
    let blocks = [ContentBlock(type: "text", text: "Test")]
    let content = MessageContent.array(blocks)
    
    let data = try encoder.encode(content)
    let object = try JSONSerialization.jsonObject(with: data)
    
    XCTAssertTrue(object is [Any])
  }
  
  // MARK: - System Prompt Tests
  
  func test_chatMessageArray_withDefaultSystemPrompt_addsSystemMessage() {
    let messages = [ChatMessage(role: .user, content: "Hello")]
    let messagesWithPrompt = messages.withDefaultSystemPrompt()
    
    XCTAssertEqual(messagesWithPrompt.count, 2)
    XCTAssertEqual(messagesWithPrompt[0].role, .system)
  }
  
  func test_chatMessageArray_existingSystemPrompt_doesNotAddAnother() {
    let messages = [
      ChatMessage(role: .system, content: "Custom system prompt"),
      ChatMessage(role: .user, content: "Hello")
    ]
    let messagesWithPrompt = messages.withDefaultSystemPrompt()
    
    XCTAssertEqual(messagesWithPrompt.count, 2)
    XCTAssertEqual(messagesWithPrompt[0].role, .system)
  }
  
  // MARK: - MessageRole Tests
  
  func test_messageRole_roundTrip() throws {
    let roles: [MessageRole] = [.system, .user, .assistant]
    
    for role in roles {
      let data = try encoder.encode(role)
      let decodedRole = try decoder.decode(MessageRole.self, from: data)
      
      XCTAssertEqual(decodedRole, role)
    }
  }
}
