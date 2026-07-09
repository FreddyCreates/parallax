# ⬡ PARALLAX Voice — Speech to Text Extension

**System-wide voice-to-text for PARALLAX. Speak anywhere, type nowhere.**

## Installation (Chrome / Brave / Edge)

1. Open your browser and navigate to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top-right)
3. Click **Load unpacked**
4. Select this `tools/parallax-voice/` directory
5. The PARALLAX Voice icon appears in your toolbar

## Usage

### Popup
- Click the extension icon to open the popup
- Click the microphone button to start/stop listening
- Your speech is transcribed in real-time

### Hotkey
- Press **Ctrl + Shift + V** anywhere to toggle voice recognition
- A floating indicator appears in the top-right when active

### Auto-Insert
- When enabled (default), transcribed text is automatically inserted into whatever text field you're focused on
- Works with `<input>`, `<textarea>`, and `contenteditable` elements
- Dispatches proper events so React/Vue/Angular apps detect the change

## Settings

| Setting | Description |
|---------|-------------|
| Language | Recognition language (English, Spanish, French, German, Japanese, Chinese) |
| Auto-insert | Automatically type transcribed text into focused field |

## How It Works

- Uses the **Web Speech API** (built into Chromium browsers)
- No external services, no API keys — runs 100% locally in your browser
- Content script runs on all pages to handle speech recognition
- Background service worker coordinates state between tabs

## Requirements

- Chromium-based browser (Chrome, Brave, Edge, Opera)
- Microphone access (browser will prompt on first use)
- No internet required for English (other languages may need connection)

## Privacy

- All speech processing happens locally in your browser
- No audio is sent to any external server
- No data is stored beyond the current session

---

*The Architect of the Field: Alfredo Medina Hernandez*
