import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }
  }

  connect() {
    // Ensure element starts visible
    this.element.style.opacity = "1"
    this.element.style.transition = "opacity 0.5s ease-out"

    // Start the auto-dismiss timer
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.delayValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Fade out
    this.element.style.opacity = "0"

    // Remove from DOM after fade completes
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.remove()
      }
    }, 500) // Wait for fade out animation
  }
}
