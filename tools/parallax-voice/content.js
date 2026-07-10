/**
 * content.js — PARALLAX Voice Content Script
 * Runs on every page. Handles actual speech recognition via Web Speech API.
 * Injects transcribed text into the currently focused input/textarea.
 */

(() => {
  "use strict";

  let recognition = null;
  let isListening = false;
  let currentLang = "en-US";
  let autoInsert = true;
  let indicator = null;

  // Create floating indicator
  function createIndicator() {
    if (indicator) return;
    indicator = document.createElement("div");
    indicator.id = "parallax-voice-indicator";
    indicator.innerHTML = `
      <div class="pxv-dot"></div>
      <span class="pxv-label">⬡ Listening...</span>
    `;
    document.body.appendChild(indicator);
  }

  function showIndicator() {
    createIndicator();
    indicator.classList.add("pxv-active");
  }

  function hideIndicator() {
    if (indicator) {
      indicator.classList.remove("pxv-active");
    }
  }

  // Initialize speech recognition
  function initRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      console.warn("[PARALLAX Voice] Speech Recognition API not supported in this browser.");
      return null;
    }

    const rec = new SpeechRecognition();
    rec.continuous = true;
    rec.interimResults = true;
    rec.lang = currentLang;
    rec.maxAlternatives = 1;

    rec.onresult = (event) => {
      let finalTranscript = "";
      let interimTranscript = "";

      for (let i = event.resultIndex; i < event.results.length; i++) {
        const result = event.results[i];
        if (result.isFinal) {
          finalTranscript += result[0].transcript;
        } else {
          interimTranscript += result[0].transcript;
        }
      }

      // Send transcript to background for popup display
      chrome.runtime.sendMessage({
        type: "TRANSCRIPT_FROM_CONTENT",
        text: finalTranscript || interimTranscript,
      });

      // Auto-insert final transcript into focused element
      if (finalTranscript && autoInsert) {
        insertTextAtCursor(finalTranscript);
      }
    };

    rec.onerror = (event) => {
      console.warn("[PARALLAX Voice] Recognition error:", event.error);
      if (event.error === "not-allowed" || event.error === "service-not-allowed") {
        stopListening();
      }
      // Auto-restart on transient errors
      if (event.error === "network" || event.error === "aborted") {
        if (isListening) {
          setTimeout(() => {
            if (isListening) startListening();
          }, 500);
        }
      }
    };

    rec.onend = () => {
      // Restart if still supposed to be listening (continuous mode workaround)
      if (isListening) {
        setTimeout(() => {
          if (isListening && recognition) {
            try {
              recognition.start();
            } catch (e) {
              // Already started
            }
          }
        }, 100);
      }
    };

    return rec;
  }

  // Insert text at cursor position in the active element
  function insertTextAtCursor(text) {
    const el = document.activeElement;
    if (!el) return;

    // Handle input/textarea
    if (el.tagName === "INPUT" || el.tagName === "TEXTAREA") {
      const start = el.selectionStart ?? el.value.length;
      const end = el.selectionEnd ?? el.value.length;
      const before = el.value.slice(0, start);
      const after = el.value.slice(end);
      el.value = before + text + after;
      el.selectionStart = el.selectionEnd = start + text.length;
      // Dispatch input event so frameworks (React, Vue) pick up the change
      el.dispatchEvent(new Event("input", { bubbles: true }));
      el.dispatchEvent(new Event("change", { bubbles: true }));
      return;
    }

    // Handle contenteditable
    if (el.isContentEditable) {
      const selection = window.getSelection();
      if (selection && selection.rangeCount > 0) {
        const range = selection.getRangeAt(0);
        range.deleteContents();
        const textNode = document.createTextNode(text);
        range.insertNode(textNode);
        range.setStartAfter(textNode);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);
        el.dispatchEvent(new Event("input", { bubbles: true }));
      }
      return;
    }
  }

  function startListening() {
    if (!recognition) {
      recognition = initRecognition();
    }
    if (!recognition) return;

    recognition.lang = currentLang;
    isListening = true;
    showIndicator();
    try {
      recognition.start();
    } catch (e) {
      // May already be started
    }
  }

  function stopListening() {
    isListening = false;
    hideIndicator();
    if (recognition) {
      try {
        recognition.stop();
      } catch (e) {
        // May already be stopped
      }
    }
    chrome.runtime.sendMessage({ type: "LISTENING_STOPPED" });
  }

  // Listen for messages from background
  chrome.runtime.onMessage.addListener((msg) => {
    switch (msg.type) {
      case "START_LISTENING":
        currentLang = msg.lang || "en-US";
        autoInsert = msg.autoInsert !== false;
        startListening();
        break;
      case "STOP_LISTENING":
        stopListening();
        break;
    }
  });

  // Keyboard shortcut: Ctrl+Shift+V (fallback for when commands API doesn't fire)
  document.addEventListener("keydown", (e) => {
    if (e.ctrlKey && e.shiftKey && e.key === "V") {
      e.preventDefault();
      if (isListening) {
        stopListening();
      } else {
        startListening();
      }
    }
  });
})();
