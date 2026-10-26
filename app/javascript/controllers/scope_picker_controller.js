import { Controller } from "@hotwired/stimulus"
import { keyboardOpener, giveBackFocus } from "lib/focus"

// The search page's "Somewhere else…" (searches/_picker): before anything is typed, the shelves, Your Texts, places
// searched lately and the whole library; typing lists the collections and works whose titles hold it. ↑↓ move through
// what's shown, Enter follows it, Escape or a tap outside closes.
export default class extends Controller {
  static targets = [ "button", "panel", "filter", "group", "item", "found", "place", "none" ]

  toggle(event) {
    if (!this.panelTarget.hidden) return this.close()
    this.opener = keyboardOpener(event)
    this.show()
  }

  show() {
    this.panelTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.filterTarget.value = ""
    this.filter()
    this.filterTarget.focus()
  }

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  escape() {
    if (this.panelTarget.hidden) return
    this.close()
    giveBackFocus(this.opener, this.panelTarget)
  }

  away(event) {
    if (!this.panelTarget.hidden && !this.element.contains(event.target)) this.close()
  }

  filter() {
    const typed = fold(this.filterTarget.value.trim())
    this.groupTargets.forEach(group => group.hidden = !!typed)
    this.foundTarget.hidden = !typed
    let found = 0
    this.placeTargets.forEach(place => {
      place.hidden = !typed || !fold(place.dataset.name).includes(typed)
      if (!place.hidden) found++
    })
    this.noneTarget.hidden = !typed || found > 0
    this.select(0)
  }

  key(event) {
    const shown = this.shown
    const at = shown.findIndex(item => item.getAttribute("aria-selected") === "true")
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.select(Math.min(at + 1, shown.length - 1))
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.select(Math.max(at - 1, 0))
    } else if (event.key === "Enter") {
      event.preventDefault()
      shown[at]?.click()
    }
  }

  select(index) {
    this.shown.forEach((item, i) => item.setAttribute("aria-selected", i === index))
    this.shown[index]?.scrollIntoView({ block: "nearest" })
  }

  // The items on show: the groups' before anything is typed, the matching places after.
  get shown() {
    return [ ...this.itemTargets, ...this.placeTargets ].filter(item => !item.hidden && !item.closest("[hidden]"))
  }
}

// Lowercased with accents dropped, so "theologie" finds "Théologie".
const fold = (text) => text.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase()
