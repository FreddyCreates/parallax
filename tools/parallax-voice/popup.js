/**
 * popup.js — PARALLAX Voice Extension Popup Controller
 * Controls the speech recognition from the popup UI.
 */

const micBtn = document.getElementById("micBtn");
const statusEl = document.getElementById("status");
const transcriptEl = document.getElementById("transcript");
const langSelect = document.getElementById("langSelect");
const autoInsert = document.getElementById("autoInsert");

let isListening = false;

// Load saved settings
chrome.storage.local.get(["pxVoiceLang", "pxVoiceAutoInsert"], (data) => {
  if (data.pxVoiceLang) langSelect.value = data.pxVoiceLang;
  if (data.pxVoiceAutoInsert !== undefined) autoInsert.checked = data.pxVoiceAutoInsert;
});

// Save settings on change
langSelect.addEventListener("change", () => {
  chrome.storage.local.set({ pxVoiceLang: langSelect.value });
  chrome.runtime.sendMessage({ type: "SET_LANG", lang: langSelect.value });
});

autoInsert.addEventListener("change", () => {
  chrome.storage.local.set({ pxVoiceAutoInsert: autoInsert.checked });
  chrome.runtime.sendMessage({ type: "SET_AUTO_INSERT", value: autoInsert.checked });
});

// Toggle listening
micBtn.addEventListener("click", () => {
  isListening = !isListening;
  chrome.runtime.sendMessage({ type: "TOGGLE_LISTENING" });
  updateUI();
});

function updateUI() {
  if (isListening) {
    micBtn.classList.add("active");
    statusEl.textContent = "Listening...";
    statusEl.classList.add("listening");
  } else {
    micBtn.classList.remove("active");
    statusEl.textContent = "Click mic or press Ctrl+Shift+V to start";
    statusEl.classList.remove("listening");
  }
}

// Listen for transcript updates from background
chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === "TRANSCRIPT_UPDATE") {
    transcriptEl.textContent = msg.text || "Your speech will appear here...";
  }
  if (msg.type === "LISTENING_STATE") {
    isListening = msg.active;
    updateUI();
  }
});

// Check current state on popup open
chrome.runtime.sendMessage({ type: "GET_STATE" }, (response) => {
  if (response) {
    isListening = response.isListening;
    if (response.transcript) transcriptEl.textContent = response.transcript;
    updateUI();
  }
});
