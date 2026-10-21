import { Controller } from "@hotwired/stimulus"

// The focus band's dropdown: the description, and under it the reader's other focuses (o), to write the passage's note
// under one of them. The list loads as it opens (the reader moves url to the passage it's on). Those noted on the
// passage come first; five show until "All N focuses…", and a long list has a filter (Enter takes the first). 1–9 and
// the arrows choose. Choosing one opens its note in the sheet's editor (focus-sheet listens for focus:chose).
export default class extends Controller {
  static targets = ["head", "frame", "list", "item", "filter", "all"]
  static values = { url: String }

  toggle() {
    this.#set(!this.isOpen)
  }

  // Esc closes it, and goes no further: the note sheet's Esc waits for the next one.
  escape(event) {
    if (!this.isOpen) return
    event.stopImmediatePropagation()
    this.#set(false)
    this.headTarget.focus()
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) this.#set(false)
  }

  key(event) {
    if (event.target.closest("input, textarea, [contenteditable]") || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "o" && this.hasFrameTarget) {
      event.preventDefault()
      this.#set(true)
      this.wantFocus = true
      this.#focusList()
      return
    }
    if (!this.isOpen || !this.hasListTarget) return
    const items = this.#shown
    if (/^[1-9]$/.test(event.key) && items[event.key - 1]) {
      event.preventDefault()
      items[event.key - 1].querySelector("a").click()
    } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const links = items.map(li => li.querySelector("a"))
      const i = links.indexOf(document.activeElement)
      const next = event.key === "ArrowDown" ? (i + 1) % links.length : (i <= 0 ? links.length : i) - 1
      links[next]?.focus()
    }
  }

  // ---------- the other focuses ----------

  listTargetConnected() {
    this.expanded = false
    this.short = this.#shown.length // five, or every noted one
    this.#number()
    this.#focusList()
  }

  all(event) {
    event.stopPropagation() // it goes from the page as it's clicked; that's no click outside
    this.expanded = true
    this.itemTargets.forEach(li => li.hidden = false)
    this.allTarget.hidden = true
    this.#number()
    this.#shown[this.short]?.querySelector("a").focus()
  }

  filter() {
    const words = this.filterTarget.value.trim().toLowerCase()
    this.itemTargets.forEach((li, i) => {
      li.hidden = words ? !li.dataset.title.includes(words) : !this.expanded && i >= this.short
    })
    if (this.hasAllTarget) this.allTarget.hidden = !!words || this.expanded
    this.#number()
  }

  filterKey(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.#shown[0]?.querySelector("a").click()
    } else if (event.key === "ArrowDown") {
      event.preventDefault()
      event.stopPropagation()
      this.#shown[0]?.querySelector("a").focus()
    }
  }

  // The link opens the note in the sheet's frame; the sheet comes to it.
  chose(event) {
    this.#set(false)
    this.dispatch("chose", { prefix: "focus", target: window, detail: { url: event.currentTarget.href } })
  }

  get #shown() { return this.itemTargets.filter(li => !li.hidden) }

  #number() {
    this.itemTargets.forEach(li => li.querySelector(".pick-num").textContent = "")
    this.#shown.slice(0, 9).forEach((li, i) => li.querySelector(".pick-num").textContent = i + 1)
  }

  // Opened with o, the filter (or the first focus) takes the keys, once the list is in.
  #focusList() {
    if (!this.wantFocus || !this.isOpen || !this.hasListTarget) return
    this.wantFocus = false
    ;(this.hasFilterTarget ? this.filterTarget : this.#shown[0]?.querySelector("a"))?.focus()
  }

  // ---------- open and shut ----------

  get isOpen() { return this.element.classList.contains("open") }

  #set(open) {
    if (open && !this.isOpen && this.hasFrameTarget) this.#load()
    this.element.classList.toggle("open", open)
    this.headTarget.setAttribute("aria-expanded", open)
  }

  // Afresh each time it opens: a note written under one of them since changes the order.
  #load() {
    const url = new URL(this.urlValue, location.href).href
    if (this.frameTarget.src === url) this.frameTarget.reload()
    else this.frameTarget.src = url
  }
}
