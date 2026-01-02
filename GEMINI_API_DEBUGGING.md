# Gemini API Response Issues - Debugging Guide

## Problem
No responses from Gemini models - messages are sent but no response comes back.

## Debug Steps

### 1. Check Console Logs in Xcode

When you send a message, look for these debug outputs in the Xcode console (Cmd+Shift+C):

```
📤 Sending request to: https://generativelanguage.googleapis.com/v1beta/models/...
📝 Request body: {"contents":[{"role":"user","parts":[{"text":"..."}]}]...
📥 Response status: 200
✅ Raw response: {...}
✨ Got response: ...
```

**What to look for:**

- ✅ `📥 Response status: 200` - Success
- ❌ `📥 Response status: 400` - Bad request (check model name, request format)
- ❌ `📥 Response status: 401` - Authentication failed (check API key)
- ❌ `📥 Response status: 403` - Forbidden (check API key permissions)
- ❌ `📥 Response status: 429` - Rate limited
- ❌ `📥 Response status: 500` - Server error

### 2. Verify API Key

Check if your API key is being saved correctly:

1. Tap Settings (⚙️)
2. Look for "Google AI API Key" field
3. Make sure it's NOT empty
4. Copy the key exactly as given from https://aistudio.google.com/apikey

**Common API key issues:**
- Key has leading/trailing spaces → Delete and re-paste
- Key is for wrong region → Get new key from https://aistudio.google.com/apikey
- Key has been revoked → Delete and regenerate
- Free tier exhausted → Check quota at https://aistudio.google.com/

### 3. Check Model Name

The model name being sent should be one of:
- `gemini-2.5-flash` ✅ CORRECT
- `gemini-2.5-pro` ✅ CORRECT
- `models/gemini-2.5-flash` ❌ WRONG (we remove the `models/` prefix)

In the console, check the URL line:
```
📤 Sending request to: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=...
```

The part between `/models/` and `:generateContent` should be just the model name.

### 4. Check Request Format

In console, look at the `📝 Request body:` line. It should look like:

```json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Hello"
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "max_output_tokens": 1024
  }
}
```

**Key points:**
- ✅ `"role": "user"` - not "User" or "USER"
- ✅ `"role": "model"` - for assistant messages (not "assistant")
- ✅ `"max_output_tokens"` - must be snake_case, not camelCase
- ✅ Temperature should be 0.0-2.0

### 5. Common Error Messages

#### "Status 400"
- Invalid request format
- Check model name is correct
- Check request JSON structure
- Check temperature is 0.0-2.0, maxTokens > 0

#### "Status 401"
- Invalid API key
- Get new key from https://aistudio.google.com/apikey

#### "Status 403"  
- API not enabled for this key
- Go to https://aistudio.google.com/ and verify access
- May need to accept terms

#### "Status 429"
- Rate limit exceeded
- Wait a few seconds and try again
- Check free tier limits

#### "Invalid response"
- Response parsing failed
- Check raw response in console
- May be a different API version

### 6. Test with curl (on Mac)

Copy your API key and test the API directly:

```bash
# Replace YOUR_API_KEY with your actual key
# Replace MODEL_NAME with gemini-2.5-flash or similar

curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "role": "user",
      "parts": [{"text": "Hello, how are you?"}]
    }],
    "generationConfig": {
      "temperature": 0.7,
      "max_output_tokens": 1024
    }
  }'
```

If this works in terminal but not in the app, the issue is with the Swift code. If it fails in terminal too, the issue is with the API key or request format.

### 7. Check Response Format

The expected successful response looks like:

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "I'm doing well, thank you for asking! ..."
          }
        ]
      },
      "finishReason": "STOP"
    }
  ],
  "usageMetadata": {
    "prompt_token_count": 5,
    "candidates_token_count": 12,
    "total_token_count": 17
  }
}
```

If you see an error response:
```json
{
  "error": {
    "code": 400,
    "message": "Invalid request format",
    "status": "INVALID_ARGUMENT"
  }
}
```

### 8. Enable Network Debugging

In Xcode, enable network logging:
1. Edit scheme (Cmd+<)
2. Run → Arguments
3. Add launch argument: `-com.apple.CoreData.SQLDebug 1`

Or add to App.swift for more details:
```swift
URLSession.shared.configuration.httpShouldSetCookies = true
URLSession.shared.configuration.waitsForConnectivity = true
```

## Solution Checklist

- [ ] API key is set in Settings
- [ ] API key has no leading/trailing spaces
- [ ] Model name is one of: gemini-2.5-flash, gemini-2.5-pro, etc.
- [ ] Console shows `📥 Response status: 200`
- [ ] Console shows `✨ Got response:`
- [ ] curl test works with same API key
- [ ] Check that google.com is not blocked
- [ ] Internet connection is active

## If Still Not Working

1. Look at the raw response in console (starts with `✅ Raw response:`)
2. Copy the exact error message
3. Check the error message against the list above
4. If it says "no candidates" or "no text", the API returned a valid response but it's empty
   - Try different model (gemini-2.5-pro instead of flash)
   - Try longer prompt with more detail
   - Check temperature is between 0-2

## Example: Successful Message Send

```
📤 Sending request to: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyD...
📝 Request body: {"contents":[{"role":"user","parts":[{"text":"Hello"}]}],"generationConfig":{"temperature":0.7,"max_output_tokens":1024}}
📥 Response status: 200
✅ Raw response: {"candidates":[{"content":{"parts":[{"text":"Hello! I'm doing well..."}]},"finishReason":"STOP"}],"usageMetadata":{"prompt_token_count":1,"candidates_token_count":5,"total_token_count":6}}
✨ Got response: Hello! I'm doing well...
```

## Example: Failed Message Send

```
📤 Sending request to: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyD...
📝 Request body: {"contents":[{"role":"user","parts":[{"text":"Hello"}]}],"generationConfig":{"temperature":0.7,"max_output_tokens":1024}}
📥 Response status: 400
❌ API Error: {"error":{"code":400,"message":"Invalid request format","status":"INVALID_ARGUMENT"}}
```

In this case, the request format is wrong. Check the request JSON structure.

