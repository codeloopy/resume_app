// JavaScript for resume edit pages
import "@hotwired/turbo-rails"
import "./controllers/resume_edit"
import "../assets/stylesheets/application.tailwind.css";

import "trix"
import "@rails/actiontext"

function dismissFlashMessages() {
  // Use class selector instead of data-controller for more reliability
  const flashMessages = document.querySelectorAll('.auto-dismiss-flash');
  flashMessages.forEach((message) => {
    // Skip if already has a timer
    if (message.dataset.flashTimer) return;

    // Set initial styles
    message.style.opacity = "1";
    message.style.transition = "opacity 0.5s ease-out";

    // Mark as having a timer
    message.dataset.flashTimer = "true";

    // Auto-dismiss after 5 seconds
    const timer = setTimeout(() => {
      if (message && message.parentNode) {
        message.style.opacity = "0";
        setTimeout(() => {
          if (message && message.parentNode) {
            message.remove();
          }
        }, 500);
      }
    }, 5000);

    // Store timer reference for cleanup
    message.dataset.timerId = timer;
  });
}

// Clear any existing timers before cache
document.addEventListener("turbo:before-cache", () => {
  const flashMessages = document.querySelectorAll('.auto-dismiss-flash');
  flashMessages.forEach((message) => {
    if (message.dataset.timerId) {
      clearTimeout(parseInt(message.dataset.timerId));
    }
  });
});

// Run on page load and Turbo navigation
document.addEventListener("turbo:load", dismissFlashMessages);
document.addEventListener("DOMContentLoaded", dismissFlashMessages);

// Also run after a small delay to catch any dynamically added messages
setTimeout(dismissFlashMessages, 100);
