import { Controller } from "@hotwired/stimulus"
import { lastSearch } from "lib/last_search"

// The reader's way back to the search a result was opened from: "← Back to results for light", over the focus. Up
// from opening a result until you leave the reader or put it away with ×.
export default class extends Controller {
  static targets = [ "link", "query" ]

  connect() {
    const url = lastSearch.get()
    const query = lastSearch.query()
    // A page from Turbo's cache may have kept it up, or half closed.
    this.element.hidden = true
    this.element.classList.remove("closing")
    this.element.style.height = ""
    if (!lastSearch.slip || !url || !query) return
    this.linkTarget.href = url
    this.queryTarget.textContent = query
    this.element.hidden = false
  }

  // Closes up (see .closing), the focus rising into its place, then goes.
  dismiss() {
    lastSearch.slip = false
    const band = this.element
    band.style.height = `${band.offsetHeight}px`
    band.offsetHeight // so the height above is where the transition starts
    band.classList.add("closing")
    band.style.height = "0px"
    band.addEventListener("transitionend", function gone(event) {
      if (event.target !== band || event.propertyName !== "height") return
      band.removeEventListener("transitionend", gone)
      band.hidden = true
    })
  }
}
