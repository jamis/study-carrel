import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken, fillId } from "lib/request"

// Switches verses client-side; the whole section is already on the page. Prose is read a sentence at a time: a
// sentence is cited by its paragraph ("12:3"), the first of a paragraph opens with a ¶, and the whole paragraph is
// one tap (or p) away.
export default class extends Controller {
  static targets = ["unit", "now", "body", "pilcrow", "prevButton", "nextButton", "position", "ref", "refUnit", "grid", "tick", "editor",
    "whole", "wholeButton"]
  static values = { current: Number, base: String, refTemplate: String, refUnitTemplate: String, positionUrl: String, unitName: String,
    groupName: String, noteUrlTemplate: String, prevUrl: String, prevLabel: String, nextUrl: String, nextLabel: String }

  connect() {
    this.bodies = new Map(this.unitTargets.map(u => [Number(u.dataset.number), u.textContent.trim()]))
    this.numbers = [...this.bodies.keys()].sort((a, b) => a - b)
    // Longer units step down in size; the server decides which (ReadingsHelper#unit_size_class).
    this.sizes = new Map(this.unitTargets.map(u => [Number(u.dataset.number), u.dataset.size]))

    this.unitIds = new Map(this.unitTargets.map(u => [Number(u.dataset.number), Number(u.dataset.unitId)]))
    // How each unit is cited ("12:3" for a sentence, else its number), its paragraph, and whether it opens one.
    this.labels = new Map(this.unitTargets.map(u => [Number(u.dataset.number), u.dataset.label]))
    this.paragraphs = new Map(this.unitTargets.map(u => [Number(u.dataset.number), u.dataset.paragraph]))
    this.opens = new Set(this.unitTargets.filter(u => u.dataset.opens === "true").map(u => Number(u.dataset.number)))
    // Which verses have a note; the editor reports changes as it autosaves.
    this.noted = new Set(this.tickTargets.filter(t => t.classList.contains("has")).map(t => Number(t.dataset.number)))
    // Likewise for kept verses; the ribbon reports those.
    this.kept = new Set(this.tickTargets.filter(t => t.classList.contains("kept")).map(t => Number(t.dataset.number)))
    this.fitRefs = () => this.refTargets.forEach(r => this.fitRef(r))
    this.refObserver = new ResizeObserver(this.fitRefs)
    this.refTargets.filter(r => r.closest(".panel")).forEach(r => this.refObserver.observe(r))
    this.updateMarkers()
    this.announce()
    this.savePosition()
  }

  disconnect() {
    this.refObserver?.disconnect()
    clearTimeout(this.saveTimer)
  }

  // In the notes panel, drop the work title when the full reference won't fit (the section name then ellipsizes).
  fitRef(ref) {
    if (!ref.closest(".panel") || !ref.clientWidth) return
    ref.classList.remove("tight")
    const needed = [...ref.children].reduce((sum, c) => sum + (c.classList.contains("ref-section") ? c.scrollWidth : c.offsetWidth), 0)
    ref.classList.toggle("tight", needed > ref.clientWidth)
  }

  next() { this.step(1) }
  previous() { this.step(-1) }
  go(event) {
    event.preventDefault() // the whole paragraph's sentences are links
    this.select(Number(event.currentTarget.dataset.number))
  }

  // Past either end of the chapter, carry on into the neighboring one.
  step(delta) {
    const i = this.numbers.indexOf(this.currentValue) + delta
    if (i >= 0 && i < this.numbers.length) return this.select(this.numbers[i])

    const url = delta > 0 ? this.nextUrlValue : this.prevUrlValue
    if (url) Turbo.visit(url)
  }

  select(number) {
    if (!this.bodies.has(number)) return
    this.currentValue = number
    history.replaceState(history.state, "", `${this.baseValue}/${number}`)
    this.render()
    this.savePosition()
  }

  // Tell the server where we are (debounced), so the app reopens here.
  savePosition() {
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      const unitId = this.unitIds.get(this.currentValue)
      if (!unitId) return
      fetch(this.positionUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ unit_id: unitId }),
        keepalive: true
      })
    }, 400)
  }

  render() {
    const n = this.currentValue
    const i = this.numbers.indexOf(n)
    this.fillStep(this.prevButtonTarget, this.numbers[i - 1], this.prevLabelValue)
    this.fillStep(this.nextButtonTarget, this.numbers[i + 1], this.nextLabelValue)
    this.positionTarget.textContent = n

    const body = this.bodies.get(n)
    this.nowTarget.className = ["now", this.sizes.get(n)].filter(Boolean).join(" ")
    this.bodyTarget.textContent = body
    if (this.hasPilcrowTarget) this.pilcrowTarget.hidden = !this.opens.has(n)
    const label = this.labels.get(n)
    this.refUnitTargets.forEach(r => r.textContent = this.refUnitTemplateValue.replace("{n}", label))
    this.refTargets.forEach(r => r.title = this.refTemplateValue.replace("{n}", label))
    this.fitRefs()
    this.tickTargets.forEach(t => {
      const current = Number(t.dataset.number) === n
      t.classList.toggle("current", current)
      t.setAttribute("aria-current", current)
      t.tabIndex = current ? 0 : -1 // the grid is one tab stop; arrow keys step through it
      if (current && this.tickTargets.includes(document.activeElement)) t.focus({ preventScroll: true })
    })

    if (this.hasWholeTarget && this.wholeTarget.classList.contains("open")) this.fillWhole()

    // Swapping the frame replaces the editor; the old one saves itself as it goes.
    this.editorTarget.src = fillId(this.noteUrlTemplateValue, this.unitIds.get(n))
    this.announce()
  }

  // The whole paragraph just opened (the menu controller runs first): fill it in and fit it to the window.
  wholeOpened() {
    if (!this.wholeTarget.classList.contains("open")) return
    this.fillWhole()
    this.fitMenu(this.wholeTarget, this.wholeButtonTarget)
    this.centerWhole()
  }

  // Fit a menu that drops from the steps to the room below its button (down to the note sheet's handle on a phone),
  // or open it upward (under the sticky reference row) when it doesn't fit below and there's more room above, since
  // the steps sit near the bottom of the window. A long menu scrolls inside, never taller than `cap`.
  fitMenu(panel, button, cap = Infinity) {
    panel.classList.remove("above")
    panel.style.maxHeight = ""
    const handle = this.element.querySelector(".panel-handle")
    const bottom = Math.min(window.innerHeight, handle?.offsetParent ? handle.getBoundingClientRect().top : Infinity)
    const top = this.element.querySelector(".reader-top")?.getBoundingClientRect().bottom ?? 0
    const { top: buttonTop, bottom: buttonBottom } = button.getBoundingClientRect()
    const below = bottom - buttonBottom - 18, above = buttonTop - Math.max(0, top) - 18
    const up = Math.min(panel.scrollHeight, cap) > below && above > below
    panel.classList.toggle("above", up)
    panel.style.maxHeight = `${Math.min(cap, Math.max(120, up ? above : below))}px`
  }

  // Every sentence of the current paragraph, each a link to itself; the one on screen is marked. The links are
  // rebuilt only for a new paragraph: choosing one mustn't swap it out from under the click (which would read as a
  // click outside, closing the menu).
  fillWhole() {
    const paragraph = this.paragraphs.get(this.currentValue)
    if (this.wholeParagraph !== paragraph) {
      this.wholeParagraph = paragraph
      const links = this.numbers.filter(n => this.paragraphs.get(n) === paragraph).map(n => {
        const link = document.createElement("a")
        link.href = `${this.baseValue}/${n}`
        link.textContent = this.bodies.get(n)
        link.dataset.number = n
        link.dataset.action = "lectio#go"
        return link
      })
      this.wholeTarget.replaceChildren(...links.flatMap((link, i) => i ? [" ", link] : [link]))
    }
    this.wholeTarget.querySelectorAll("a").forEach(link => {
      const n = Number(link.dataset.number), current = n === this.currentValue
      link.classList.toggle("current", current)
      link.classList.toggle("has", this.noted.has(n))
      if (current) link.setAttribute("aria-current", "true"); else link.removeAttribute("aria-current")
    })
    this.centerWhole()
  }

  centerWhole() {
    const current = this.wholeTarget.querySelector(".current")
    if (current) this.wholeTarget.scrollTop = current.offsetTop - (this.wholeTarget.clientHeight - current.offsetHeight) / 2
  }

  // The Keep ribbon follows the verse on screen.
  announce() {
    this.dispatch("changed", { detail: { unitId: this.unitIds.get(this.currentValue) } })
  }

  keepChanged({ detail: { unitId, kept } }) {
    const number = [...this.unitIds].find(([, id]) => id === unitId)?.[0]
    if (number === undefined) return
    if (kept) this.kept.add(number); else this.kept.delete(number)
    this.updateMarkers()
  }

  // The grid of every verse just opened (the menu controller runs first): start on the current one,
  // scrolled into view in a long chapter.
  gridOpened() {
    if (!this.gridTarget.classList.contains("open")) return
    const tick = this.tickTargets.find(t => Number(t.dataset.number) === this.currentValue)
    if (!tick) return
    this.fitMenu(this.gridTarget, this.gridTarget.closest(".steps-menu").querySelector("button"), 360)
    this.gridTarget.scrollTop = tick.offsetTop - (this.gridTarget.clientHeight - tick.offsetHeight) / 2
    tick.focus({ preventScroll: true })
  }

  noteSaved({ detail: { unitId, noted } }) {
    const number = [...this.unitIds].find(([, id]) => id === unitId)?.[0]
    if (number === undefined) return
    if (noted) this.noted.add(number); else this.noted.delete(number)
    this.updateMarkers()
  }

  // The grid marks every verse that has a note, and every one that's kept.
  updateMarkers() {
    this.tickTargets.forEach(tick => {
      const n = Number(tick.dataset.number)
      const has = this.noted.has(n)
      const kept = this.kept.has(n)
      tick.classList.toggle("has", has)
      tick.classList.toggle("kept", kept)
      tick.setAttribute("aria-label", `${this.unitNameValue} ${this.labels.get(n)}${has ? ", has a note" : ""}${kept ? ", kept" : ""}`)
    })
  }

  // A step arrow names where it goes (as its tooltip and label): the neighboring verse, or at a chapter's edge
  // the neighboring chapter. Hidden at either end of the text.
  fillStep(button, number, edgeLabel) {
    const label = number !== undefined ? `${this.unitNameValue} ${this.labels.get(number)}` : edgeLabel
    button.hidden = !label
    button.title = label
    button.setAttribute("aria-label", label)
  }

  touchStart(event) {
    // Scrolling the verse grid or the whole paragraph must not also turn the page.
    if (this.gridTarget.contains(event.target) || (this.hasWholeTarget && this.wholeTarget.contains(event.target))) {
      this.touchStartPoint = undefined
      return
    }
    const { clientX, clientY } = event.touches[0]
    this.touchStartPoint = { x: clientX, y: clientY }
  }

  // Only a mostly-horizontal swipe turns the page; scrolling a long passage drifts sideways too.
  touchEnd(event) {
    if (!this.touchStartPoint) return
    const { clientX, clientY } = event.changedTouches[0]
    const dx = clientX - this.touchStartPoint.x
    const dy = clientY - this.touchStartPoint.y
    this.touchStartPoint = undefined
    if (Math.abs(dx) > 60 && Math.abs(dx) > 2 * Math.abs(dy)) this.step(dx < 0 ? 1 : -1)
  }

  key(event) {
    if (event.target.closest("input, textarea, [contenteditable]") || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "ArrowRight" || event.key === "j") this.next()
    if (event.key === "ArrowLeft" || event.key === "k") this.previous()
    if (event.key === "p" && this.hasWholeButtonTarget) this.wholeButtonTarget.click()
  }
}
