import { Controller } from "@hotwired/stimulus"
import { lastSearch } from "lib/last_search"

// The empty search page's offer of the search you last made in this sitting: shown, naming it, when there is one.
export default class extends Controller {
  static targets = [ "link", "query" ]

  connect() {
    const url = lastSearch.get()
    const query = lastSearch.query()
    if (!url || !query) return
    this.linkTarget.href = url
    lastSearch.name(this.queryTarget, query)
    this.element.hidden = false
  }
}
