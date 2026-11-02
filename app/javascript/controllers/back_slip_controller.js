import { Controller } from "@hotwired/stimulus"
import { lastSearch } from "lib/last_search"

// The reader's way back to the search a result was opened from: "← Back to results for light", over the focus. Up
// from opening a result until you leave the reader or put it away with ×. Under it, the results either side of where
// you are ("‹ Isaiah 22:4 · 3 of 13 · Isaiah 40:2 ›"), stepped to with [ and ]: within the chapter by the reader
// itself, beyond it by a visit. Where they stand around the chapter comes from the server once a page (around_url);
// the way back is kept on the result you're on, or the one before it.
export default class extends Controller {
  static targets = [ "link", "query", "results", "previous", "where", "next" ]
  static values = { aroundUrl: String, number: Number }

  connect() {
    const url = lastSearch.get()
    const query = lastSearch.query()
    // A page from Turbo's cache may have kept it up, or half closed.
    this.element.hidden = true
    this.element.classList.remove("closing")
    this.element.style.height = ""
    this.around = null
    this.clearResults()
    if (!lastSearch.slip || !url || !query) return
    this.linkTarget.href = url
    lastSearch.name(this.queryTarget, query)
    this.element.hidden = false
    this.load(url)
  }

  disconnect() {
    this.request?.abort()
  }

  // The results around this chapter, for the search last made (its page aside).
  async load(url) {
    const around = new URL(this.aroundUrlValue, location.origin)
    new URL(url, location.origin).searchParams.forEach((value, key) => { if (key !== "page") around.searchParams.set(key, value) })
    this.request = new AbortController()
    try {
      const response = await fetch(around, { headers: { Accept: "application/json" }, signal: this.request.signal })
      if (response.ok) this.around = await response.json()
    } catch (error) {
      if (error.name === "AbortError") return
    }
    if (this.around) this.render(); else this.resultsTarget.hidden = true
  }

  moved({ detail: { number } }) {
    this.numberValue = number
    this.render()
  }

  key(event) {
    if (!lastSearch.slip || event.repeat || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, [contenteditable]")) return
    if (event.key === "[" && !this.previousTarget.hidden) this.previousTarget.click()
    if (event.key === "]" && !this.nextTarget.hidden) this.nextTarget.click()
  }

  render() {
    if (!this.around) return
    const { total, before, hits, per_page: perPage } = this.around
    if (!total) return this.resultsTarget.hidden = true

    const n = this.numberValue
    const at = hits.findIndex(h => h.number === n)
    const below = hits.filter(h => h.number < n).length // results in the chapter before this verse
    const previous = (at >= 0 ? hits[at - 1] : hits[below - 1]) || this.around.previous
    const next = (at >= 0 ? hits[at + 1] : hits[below]) || this.around.next
    const passed = before + below // results before this verse

    this.fill(this.previousTarget, previous, "Previous result", "[")
    this.fill(this.nextTarget, next, "Next result", "]")
    this.whereTarget.replaceChildren(...(at >= 0 ? [ this.bold(passed + 1), ` of ${total}` ]
      : !previous ? [ `before the first of ${total}` ] : !next ? [ `past the last of ${total}` ]
      : [ this.span("long", `between ${passed} and ${passed + 1} of ${total}`), this.span("short", `${passed}–${passed + 1} of ${total}`) ]))

    // Back to the results lands on the one you're on, or else the one before (or after) where you are.
    const [ landing, position ] = at >= 0 ? [ hits[at], passed + 1 ] : previous ? [ previous, passed ] : [ next, passed + 1 ]
    const saved = new URL(lastSearch.get(), location.origin)
    const page = Math.ceil(position / perPage)
    if (page > 1) saved.searchParams.set("page", page); else saved.searchParams.delete("page")
    saved.hash = `r-${landing.id}`
    lastSearch.set(saved.pathname + saved.search + saved.hash)
    this.linkTarget.href = lastSearch.get()
  }

  // A result in this chapter is a step the reader takes itself (lectio#go); one beyond it, a visit.
  fill(link, result, label, key) {
    link.hidden = !result
    if (!result) return
    link.href = result.url
    const name = link.querySelector(".back-slip-name")
    name.textContent = result.name
    name.nextElementSibling.textContent = result.unit
    link.title = `${label}: ${result.name}${result.unit} (${key})`
    link.setAttribute("aria-label", link.title)
    if (this.around.hits.includes(result)) {
      link.dataset.action = "lectio#go"
      link.dataset.number = result.number
    } else {
      delete link.dataset.action
      delete link.dataset.number
    }
  }

  bold(text) {
    const b = document.createElement("b")
    b.textContent = text
    return b
  }

  // Between two results, said in full, or on a phone "3–4 of 13" (see .back-slip-where), leaving the titles room.
  span(className, text) {
    const span = document.createElement("span")
    span.className = className
    span.textContent = text
    return span
  }

  // Room is kept for the results while they load, so the focus doesn't drop when they come.
  clearResults() {
    this.resultsTarget.hidden = false
    this.previousTarget.hidden = this.nextTarget.hidden = true
    this.whereTarget.replaceChildren()
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
