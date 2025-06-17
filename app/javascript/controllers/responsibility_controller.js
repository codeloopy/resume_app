import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  connect() {
    this.index = this.containerTarget.children.length
  }

  add(event) {
    event.preventDefault()

    const skills_accordion = document.querySelector("details")
    skills_accordion.open = true
    skills_accordion.scrollIntoView({ behavior: "smooth" })

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
