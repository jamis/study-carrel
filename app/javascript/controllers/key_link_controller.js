import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// A link with a key of its own (the notes page's Reread, r): pressing it anywhere but in a field follows the link.
export default class extends Controller {
  static values = { key: String }

  key(event) {
    if (event.key !== this.keyValue || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    event.preventDefault()
    Turbo.visit(this.element.href)
  }
}
