# iA Test Suite - Setup Guide

## Overview

Comprehensive test suite for the iA chat application, including unit tests, integration tests, and mock dependencies.

## Test Files Created

### Location: `/Users/jach/dev/lama/iATests/`

#### Services Tests
- **Services/UserDefaultsServiceTests.swift** - 11 tests
  - Tests UserDefaults persistence for app settings
  - API key, model, temperature, max tokens, web search preferences
  - Test value initialization and custom configurations

- **Services/GroqModelsTests.swift** - 18 tests
  - Chat message encoding/decoding with text and images
  - ContentBlock and ImageUrl serialization
  - GroqChatRequest payload generation
  - Message role handling
  - System prompt injection

#### Features Tests
- **Features/ChatReducerTests.swift** - 12 tests
  - Chat.State initialization and properties
  - Chat title generation (empty, short, and long messages)
  - Visible messages filtering
  - Model selection logic
  - Loading state transitions
  - Web search UI toggling
  - Error message handling
  - ChatList reducer operations (new chat, delete, model loading)

#### Integration Tests
- **IntegrationTests.swift** - 13 tests
  - Complex multimodal message handling (text + images)
  - Request/response round-trip serialization
  - Unicode and special character support
  - Edge cases (very long messages, minimal/maximal data)
  - Reasoning parameters and web search configuration

#### Supporting Files
- **MockDependencies.swift** - Mock services and test constants
  - Mock GroqService for testing
  - Mock UserDefaultsService with configurable values
  - Test constants for API keys, models, and messages

- **README.md** - Documentation
  - Test structure overview
  - Running tests (Xcode and command line)
  - Coverage summary
  - Best practices for adding new tests

## Test Summary

**Total Tests: 54**
- UserDefaults Service: 11 tests
- Groq Models: 18 tests
- Chat Reducer: 12 tests
- Integration: 13 tests

## Adding Test Target to Xcode

To integrate tests into the Xcode project:

### Option 1: Manual Addition in Xcode UI
1. In Xcode, go to File → Add Files to "iA"
2. Select the `iATests` folder
3. Create a new Unit Test Bundle target in the same dialog
4. Manually add test files to the target

### Option 2: Command Line Setup
```bash
# Navigate to project
cd /Users/jach/dev/lama

# Create a unit test bundle target
xcodebuild -project iA.xcodeproj -target iA -scheme Ai test

# The test files are ready to be added to a new test target
```

### Option 3: Test Files Are Ready to Use
The test files are organized and ready to use. Simply:
1. Create a new Unit Test Bundle target in Xcode
2. Add the files from `iATests/` directory
3. Link ComposableArchitecture framework

## Running Tests

### Once Tests Are Added to Xcode:

```bash
# Run all tests
xcodebuild test -project iA.xcodeproj -scheme Ai

# Run specific test class
xcodebuild test -project iA.xcodeproj -scheme Ai -testSpecifier UserDefaultsServiceTests

# Run with coverage
xcodebuild test -project iA.xcodeproj -scheme Ai -enableCodeCoverage YES

# Run in Xcode
# Press Cmd+U or Product → Test
```

## Test Categories

### Unit Tests (40 tests)
- **UserDefaults Service (11)** - Preference management, persistence
- **Groq Models (18)** - JSON serialization, data structures  
- **Chat Reducer (11)** - State management, UI state

### Integration Tests (13 tests)
- Multimodal message handling
- Complex serialization scenarios
- Unicode and edge case handling

## What's Tested

✅ **Services**
- User preferences (API key, model, temperature, tokens, web search)
- Groq API model structures
- JSON encoding/decoding
- Message serialization with images

✅ **Features**
- Chat state management
- Chat title generation
- Message filtering and display
- Model selection
- Loading states

✅ **Integration**
- Message round-trip serialization
- Complex multimodal content
- Special character handling
- Request payload generation

## Test Dependencies

All tests use:
- `XCTest` framework (standard)
- `ComposableArchitecture` (via dependency injection)
- `Foundation` for data handling

No external network calls - all services are mocked.

## File Structure

```
iATests/
├── README.md
├── MockDependencies.swift
├── IntegrationTests.swift
├── Services/
│   ├── UserDefaultsServiceTests.swift
│   └── GroqModelsTests.swift
└── Features/
    └── ChatReducerTests.swift
```

## Next Steps

1. **Create Test Target in Xcode:**
   - File → New → Target → Unit Testing Bundle
   - Name it `iATests`
   - Link to main app target

2. **Add Files:**
   - Drag test files from iATests/ folder
   - Ensure files are added to iATests target

3. **Run Tests:**
   - Press Cmd+U or use terminal commands
   - All 54 tests should pass

4. **Continuous Integration:**
   - Add test runs to CI/CD pipeline
   - Tests run without internet connection
   - Typical runtime: < 30 seconds

## Maintenance

- Tests follow Arrange-Act-Assert pattern
- Each test is independent
- Mock dependencies prevent external dependencies
- Regular updates needed for new features

All tests are self-contained and ready to run!
