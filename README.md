# Mac Global Translation

Mac Global Translation is a lightweight macOS menu bar app for translating text in almost any input field. Put the cursor in a text box, press your global shortcut, and the app copies the current text, translates it with your selected AI provider, then pastes the translated result back.

## Features

- Menu bar app with a compact settings window
- Configurable global shortcut
- Target language selector with common world languages
- Multiple AI providers:
  - DeepSeek
  - OpenAI
  - Anthropic Claude
  - Google Gemini
  - Qwen / DashScope
  - Kimi / Moonshot
  - OpenRouter
  - SiliconFlow
- Per-provider API keys stored in macOS Keychain
- Local build script, no Xcode project required
- Generated macOS app icon

## Build

```bash
cd macos/InputTranslatorMac
./build.sh
```

The app will be generated at:

```text
macos/InputTranslatorMac/build/Input Translator.app
```

## Usage

1. Open `Input Translator.app`.
2. Click the `译` menu bar item.
3. Open `Settings...`.
4. Choose an AI provider.
5. Paste the corresponding API key.
6. Choose a target language and model.
7. Choose a global shortcut.
8. Put the cursor in an input field and press the shortcut.

The default shortcut is:

```text
Control + Option + T
```

## macOS Permissions

The app simulates copy and paste, so macOS requires Accessibility permission.

Open:

```text
System Settings -> Privacy & Security -> Accessibility
```

Then allow `Input Translator`.

If permission was already enabled but the app still prompts again, remove the old `Input Translator` entry from Accessibility and add the current app again. Local rebuilds can make macOS treat the app as a new binary.

## Notes

- API keys are stored locally in macOS Keychain.
- Translation text is sent to the selected AI provider.
- Build output is intentionally ignored by Git.
- This project currently focuses on macOS.
