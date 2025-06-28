import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    action: String,
    slug: String
  }

  trackEvent() {
    if (typeof gtag !== 'undefined') {
      gtag('event', this.actionValue, {
        event_category: 'resume',
        event_label: this.slugValue
      });
    } else {
      console.log('Google Analytics not loaded yet');
    }
  }
}
