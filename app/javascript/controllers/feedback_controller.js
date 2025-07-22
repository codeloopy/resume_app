import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]

  open(event) {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
  }

  cancel() {
    this.modalTarget.classList.add("hidden")
  }

  trackFormSubmission(event) {
    // Track form submission
    if (typeof gtag !== 'undefined') {
      gtag('event', 'feedback_form_submitted', {
        event_category: 'feedback',
        event_label: 'user_feedback_submission'
      });
    } else {
      console.log('Google Analytics not loaded yet');
    }
  }
}
