//
//  UserDefaultsServiceTests.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import XCTest
import ComposableArchitecture

final class UserDefaultsServiceTests: XCTestCase {
  
  func test_getDefaultModel_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let model = service.getDefaultModel()
    XCTAssertEqual(model, "models/gemini-3-flash-preview")
  }

  func test_getTemperature_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let temperature = service.getTemperature()
    XCTAssertEqual(temperature, 0.7)
  }

  func test_getMaxTokens_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let maxTokens = service.getMaxTokens()
    XCTAssertEqual(maxTokens, 1024)
  }
  
  func test_getAutoSaveChatsEnabled_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let enabled = service.getAutoSaveChatsEnabled()
    XCTAssertTrue(enabled)
  }
  
  func test_setAndGetDefaultModel() {
    var userDefaults: [String: Any] = [:]

    let service = UserDefaultsService(
      getDefaultModel: {
        userDefaults["defaultModel"] as? String ?? "models/gemini-3-flash-preview"
      },
      setDefaultModel: { value in
        userDefaults["defaultModel"] = value
      },
      getTemperature: { 0.7 },
      setTemperature: { _ in },
      getMaxTokens: { 1024 },
      setMaxTokens: { _ in },
      getAutoSaveChatsEnabled: { true },
      setAutoSaveChatsEnabled: { _ in },
      resetToDefaults: { }
    )

    let newModel = "models/gemini-3-pro"
    service.setDefaultModel(newModel)
    XCTAssertEqual(service.getDefaultModel(), newModel)
  }
  
  func test_setAndGetTemperature() {
    var userDefaults: [String: Any] = [:]

    let service = UserDefaultsService(
      getDefaultModel: { "models/gemini-3-flash-preview" },
      setDefaultModel: { _ in },
      getTemperature: {
        userDefaults["temperature"] as? Double ?? 0.7
      },
      setTemperature: { value in
        userDefaults["temperature"] = value
      },
      getMaxTokens: { 1024 },
      setMaxTokens: { _ in },
      getAutoSaveChatsEnabled: { true },
      setAutoSaveChatsEnabled: { _ in },
      resetToDefaults: { }
    )

    let newTemperature = 0.5
    service.setTemperature(newTemperature)
    XCTAssertEqual(service.getTemperature(), newTemperature)
  }

  func test_setAndGetMaxTokens() {
    var userDefaults: [String: Any] = [:]

    let service = UserDefaultsService(
      getDefaultModel: { "models/gemini-3-flash-preview" },
      setDefaultModel: { _ in },
      getTemperature: { 0.7 },
      setTemperature: { _ in },
      getMaxTokens: {
        userDefaults["maxTokens"] as? Int ?? 1024
      },
      setMaxTokens: { value in
        userDefaults["maxTokens"] = value
      },
      getAutoSaveChatsEnabled: { true },
      setAutoSaveChatsEnabled: { _ in },
      resetToDefaults: { }
    )

    let newMaxTokens = 2048
    service.setMaxTokens(newMaxTokens)
    XCTAssertEqual(service.getMaxTokens(), newMaxTokens)
  }

  func test_setAndGetAutoSaveChatsEnabled() {
    var userDefaults: [String: Any] = [:]

    let service = UserDefaultsService(
      getDefaultModel: { "models/gemini-3-flash-preview" },
      setDefaultModel: { _ in },
      getTemperature: { 0.7 },
      setTemperature: { _ in },
      getMaxTokens: { 1024 },
      setMaxTokens: { _ in },
      getAutoSaveChatsEnabled: {
        userDefaults["autoSaveChatsEnabled"] as? Bool ?? true
      },
      setAutoSaveChatsEnabled: { value in
        userDefaults["autoSaveChatsEnabled"] = value
      },
      resetToDefaults: { }
    )

    service.setAutoSaveChatsEnabled(false)
    XCTAssertFalse(service.getAutoSaveChatsEnabled())

    service.setAutoSaveChatsEnabled(true)
    XCTAssertTrue(service.getAutoSaveChatsEnabled())
  }
}
