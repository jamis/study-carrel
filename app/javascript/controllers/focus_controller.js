import { Controller } from "@hotwired/stimulus"

// The focus band's description dropdown.
export default class extends Controller {
  static targets = ["head"]

  toggle() {
    this.#set(!this.element.classList.contains("open"))
  }

  escape() {
    if (!this.element.classList.contains("open")) return
    this.#set(false)
    this.headTarget.focus()
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) this.#set(false)
  }

  #set(open) {
    this.element.classList.toggle("open", open)
    this.headTarget.setAttribute("aria-expanded", open)
  }
}
