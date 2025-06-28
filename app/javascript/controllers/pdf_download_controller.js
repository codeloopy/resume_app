import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    slug: String
  }

  async download() {
    if (typeof gtag !== 'undefined') {
      gtag('event', 'download_pdf', {
        event_category: 'resume',
        event_label: this.slugValue
      });
    }

    try {
      // Show downloading state
      this.element.textContent = "Generating PDF...";
      this.element.disabled = true;

      // Fetch the PDF as a blob
      const response = await fetch(this.urlValue);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const blob = await response.blob();

      // Create download link
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `resume_${this.slugValue}.pdf`;

      // Trigger download
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Clean up
      window.URL.revokeObjectURL(url);

      // Reset button
      setTimeout(() => {
        this.element.textContent = "Download PDF";
        this.element.disabled = false;
      }, 1000);

    } catch (error) {
      console.error('Download failed:', error);

      // Fallback to direct link
      const link = document.createElement('a');
      link.href = this.urlValue;
      link.download = `resume_${this.slugValue}.pdf`;
      link.target = '_blank';

      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Reset button
      setTimeout(() => {
        this.element.textContent = "Download PDF";
        this.element.disabled = false;
      }, 1000);
    }
  }
}
