import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// "/" goes to search: it focuses the search box on a page that has one, and otherwise follows this link (the
// menu's Search item).
export default class extends Controller {
  key(event) {
    if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    event.preventDefault()
    const input = document.querySelector("[data-search-input]")
    if (input) {
      input.focus()
      input.select()
    } else {
      Turbo.visit(this.element.href)
    }
  }
}
