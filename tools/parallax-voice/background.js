/**
 * background.js — PARALLAX Voice Service Worker
 * Manages state and coordinates between popup and content scripts.
 */

let state = {
  isListening: false,
  lang: "en-US",
  autoInsert: true,
  transcript: "",
};

// Handle messages from popup and content scripts
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  switch (msg.type) {
    case "TOGGLE_LISTENING":
      state.isListening = !state.isListening;
      broadcastToContentScripts({
        type: state.isListening ? "START_LISTENING" : "STOP_LISTENING",
        lang: state.lang,
        autoInsert: state.autoInsert,
      });
      break;

    case "SET_LANG":
      state.lang = msg.lang;
      break;

    case "SET_AUTO_INSERT":
      state.autoInsert = msg.value;
      break;

    case "GET_STATE":
      sendResponse(state);
      return true;

    case "TRANSCRIPT_FROM_CONTENT":
      state.transcript = msg.text;
      chrome.runtime.sendMessage({ type: "TRANSCRIPT_UPDATE", text: msg.text });
      break;

    case "LISTENING_STOPPED":
      state.isListening = false;
      chrome.runtime.sendMessage({ type: "LISTENING_STATE", active: false });
      break;
  }
});

// Broadcast message to all content scripts
function broadcastToContentScripts(message) {
  chrome.tabs.query({}, (tabs) => {
    for (const tab of tabs) {
      if (tab.id) {
        chrome.tabs.sendMessage(tab.id, message).catch(() => {
          // Tab might not have content script loaded
        });
      }
    }
  });
}

// Handle keyboard shortcut command
chrome.commands?.onCommand?.addListener((command) => {
  if (command === "toggle-voice") {
    state.isListening = !state.isListening;
    broadcastToContentScripts({
      type: state.isListening ? "START_LISTENING" : "STOP_LISTENING",
      lang: state.lang,
      autoInsert: state.autoInsert,
    });
    chrome.runtime.sendMessage({ type: "LISTENING_STATE", active: state.isListening });
  }
});
