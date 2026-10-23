import { Controller } from "@hotwired/stimulus"
import { lastSearch } from "lib/last_search"

// A Search link (the rail's, the menu's) that goes back to the search you last made in this sitting, scrolled to the
// result you opened from it, rather than to an empty search page.
export default class extends Controller {
  connect() {
    const url = lastSearch.get()
    if (url) this.element.href = url
  }
}
