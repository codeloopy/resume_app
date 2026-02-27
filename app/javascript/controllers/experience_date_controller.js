import { Controller } from "@hotwired/stimulus"

// Defaults end date year to current year when empty (keeps all years in dropdown)
export default class extends Controller {
  connect() {
    this.endYearSelect = this.element.querySelector('select[name*="end_date(1i)"]')
    if (!this.endYearSelect) return

    const currentYear = new Date().getFullYear()
    const selectedYear = parseInt(this.endYearSelect.value, 10)

    // Default to current year when empty
    if (isNaN(selectedYear) || selectedYear === 0) {
      const currentYearOption = Array.from(this.endYearSelect.options).find(
        (opt) => opt.value === String(currentYear)
      )
      if (currentYearOption) {
        this.endYearSelect.value = String(currentYear)
      }
    }
  }
}
