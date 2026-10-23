import { Controller } from "@hotwired/stimulus"
import { lastSearch } from "lib/last_search"

// A page of search results: remembered as the last search (see lib/last_search), and, when a result is opened, with
// that result, so coming back by Search lands on it, lit.
export default class extends Controller {
  connect() {
    lastSearch.set(location.pathname + location.search + location.hash)
    const id = location.hash.slice(1)
    const result = id && document.getElementById(id)
    if (!result) return
    result.classList.add("returned")
    result.scrollIntoView({ block: "center" })
  }

  open(event) {
    const result = event.currentTarget.closest("[id]")
    lastSearch.set(`${location.pathname}${location.search}#${result.id}`)
  }
}
