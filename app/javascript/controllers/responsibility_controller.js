import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  connect() {
    this.index = this.containerTarget.children.length
    this.sectionType = this.element.dataset.responsibilityScope
  }

  add(event) {
    event.preventDefault()

    if (this.sectionType === "skills") {
      const skillsAccordion = document.querySelector("#skills-section")
      if (skillsAccordion) {
        skillsAccordion.open = true
        skillsAccordion.scrollIntoView({ behavior: "smooth" })
      }
    }

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.index)
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    this.index++
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest(".nested-fields")
    if (item.dataset.newRecord === "true") {
      item.remove()
    } else {
      item.querySelector("input[name*='_destroy']").value = 1
      item.style.display = "none"
    }
  }
}
