import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }
  static targets = ["button"]

  copy() {
    if (navigator.clipboard && window.isSecureContext) {
      // Use the modern Clipboard API
      navigator.clipboard.writeText(this.textValue).then(() => {
        this.showSuccess();
      }).catch(err => {
        console.error('Failed to copy: ', err);
        this.fallbackCopy();
      });
    } else {
      // Fallback for older browsers
      this.fallbackCopy();
    }
  }

  fallbackCopy() {
    // Create a temporary textarea element
    const textArea = document.createElement("textarea");
    textArea.value = this.textValue;
    textArea.style.position = "fixed";
    textArea.style.left = "-999999px";
    textArea.style.top = "-999999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
      document.execCommand('copy');
      this.showSuccess();
    } catch (err) {
      console.error('Fallback copy failed: ', err);
      this.showError();
    }

    document.body.removeChild(textArea);
  }

  showSuccess() {
    const originalText = this.element.textContent;
    this.element.textContent = "Link copied!";
    this.element.classList.add("text-green-600");

    // Track the copy event
    if (typeof gtag !== 'undefined') {
      gtag('event', 'copy_link_for_public_resume', {
        event_category: 'resume',
        event_label: this.textValue.split('/').pop()
      });
    } else {
      console.log('Google Analytics not loaded yet');
    }

    setTimeout(() => {
      this.element.textContent = originalText;
      this.element.classList.remove("text-green-600");
    }, 2000);
  }

  showError() {
    const originalText = this.element.textContent;
    this.element.textContent = "Failed to copy";
    this.element.classList.add("text-red-600");

    setTimeout(() => {
      this.element.textContent = originalText;
      this.element.classList.remove("text-red-600");
    }, 2000);
  }
}
