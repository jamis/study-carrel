import { Controller } from "@hotwired/stimulus"

// The Keep ribbon. Tapping the empty ribbon keeps the verse on screen (and offers Undo / Add a remark for a few
// seconds); tapping a kept ribbon opens a small popover for the remark, or to release it. The reader announces
// each verse it shows with lectio:changed, and this announces keeps and releases with keep:changed.
export default class extends Controller {
  static targets = ["button", "toast", "pop", "remark"]
  static values = { kept: Object, unitId: Number, urlTemplate: String }

  connect() {
    this.kept = new Map(Object.entries(this.keptValue).map(([id, remark]) => [Number(id), remark]))
    this.render()
  }

  disconnect() { clearTimeout(this.toastTimer) }

  sync({ detail: { unitId } }) {
    this.unitIdValue = unitId
    this.hideToast()
    this.closePop()
    this.render()
  }

  press() { this.isKept ? this.togglePop() : this.keep() }

  // "b" does what tapping the ribbon does.
  key(event) {
    if (event.key !== "b" || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    this.press()
  }

  keep() {
    this.kept.set(this.unitIdValue, "")
    this.render()
    this.announce(true)
    this.showToast()
    this.send("POST")
  }

  release() {
    this.kept.delete(this.unitIdValue)
    this.hideToast()
    this.closePop()
    this.render()
    this.announce(false)
    this.send("DELETE")
  }

  saveRemark() {
    const remark = this.remarkTarget.value.trim()
    this.kept.set(this.unitIdValue, remark)
    this.send("PATCH", { keep: { remark } })
  }

  openRemark() {
    this.hideToast()
    this.openPop()
  }

  togglePop() { this.popTarget.hidden ? this.openPop() : this.closePop() }

  openPop() {
    this.remarkTarget.value = this.kept.get(this.unitIdValue) ?? ""
    this.popTarget.hidden = false
    this.remarkTarget.focus()
  }

  // Closing by Enter or by a tap elsewhere both blur the field first, so the remark has already been saved.
  close() { this.closePop(); this.buttonTarget.focus() }
  closePop() { this.popTarget.hidden = true }

  escape() {
    if (this.popTarget.hidden && this.toastTarget.hidden) return
    this.hideToast()
    this.close()
  }

  away(event) {
    if (!this.element.contains(event.target)) { this.closePop(); this.hideToast() }
  }

  showToast() {
    this.toastTarget.hidden = false
    clearTimeout(this.toastTimer)
    this.toastTimer = setTimeout(() => this.hideToast(), 6000)
  }

  hideToast() {
    clearTimeout(this.toastTimer)
    this.toastTarget.hidden = true
  }

  render() {
    const kept = this.isKept
    this.buttonTarget.classList.toggle("kept", kept)
    this.buttonTarget.setAttribute("aria-pressed", kept)
    this.buttonTarget.setAttribute("aria-label", kept ? "Kept. Add a remark or release" : "Keep this passage")
    this.buttonTarget.title = kept ? "Kept: add a remark or release (b)" : "Keep this passage (b)"
  }

  announce(kept) {
    this.dispatch("changed", { detail: { unitId: this.unitIdValue, kept } })
  }

  // Send the change for the verse shown now; if it doesn't take, put the ribbon back as it was.
  async send(method, body) {
    const unitId = this.unitIdValue
    try {
      const response = await fetch(this.urlTemplateValue.replace("%7Bid%7D", unitId).replace("{id}", unitId), {
        method,
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
        body: body && JSON.stringify(body),
        keepalive: true
      })
      if (!response.ok) throw new Error(response.statusText)
    } catch {
      if (method === "PATCH") return
      const kept = method === "DELETE"
      if (kept) this.kept.set(unitId, ""); else this.kept.delete(unitId)
      if (unitId === this.unitIdValue) this.render()
      this.dispatch("changed", { detail: { unitId, kept } })
      alert("Couldn't save that. Check your connection and try again.")
    }
  }

  get isKept() { return this.kept.has(this.unitIdValue) }
}
