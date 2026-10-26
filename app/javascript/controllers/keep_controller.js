import { Controller } from "@hotwired/stimulus"
import { csrfToken, fillId } from "lib/request"
import { keyboardOpener, giveBackFocus } from "lib/focus"

// The Keep ribbon. Tapping the empty ribbon keeps the verse on screen (and offers Undo / Add a remark for a few
// seconds); tapping a kept ribbon opens a small popover for the remark, or to release it. Save, Enter or a tap
// elsewhere saves the remark and the toast comes back with it; Esc leaves it as it was. The reader announces each verse
// it shows with lectio:changed, and this announces keeps and releases with keep:changed.
export default class extends Controller {
  static targets = ["button", "toast", "toastRemark", "toastKept", "toastSaved", "pop", "remark"]
  static values = { kept: Object, unitId: Number, urlTemplate: String }

  connect() {
    this.kept = new Map(Object.entries(this.keptValue).map(([id, remark]) => [Number(id), remark]))
    this.render()
  }

  disconnect() {
    this.commitRemark()
    clearTimeout(this.toastTimer)
  }

  // A remark being written when the verse changes is saved to the verse it was written on.
  sync({ detail: { unitId } }) {
    this.commitRemark()
    this.unitIdValue = unitId
    this.hideToast()
    this.closePop()
    this.render()
  }

  press(event) {
    if (!this.isKept) return this.keep()
    if (this.popTarget.hidden) this.opener = keyboardOpener(event)
    this.togglePop()
  }

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

  save() {
    const saved = this.commitRemark()
    this.close()
    if (saved) this.showToast(this.kept.get(this.unitIdValue))
  }

  // Esc: put the popover away and leave the remark as it was.
  cancel() { this.close() }

  // Send the remark in the open popover if it changed; true if it did.
  commitRemark() {
    if (!this.hasPopTarget || this.popTarget.hidden || !this.isKept) return false
    const remark = this.remarkTarget.value.trim()
    const previous = this.kept.get(this.unitIdValue) ?? ""
    if (remark === previous) return false
    this.kept.set(this.unitIdValue, remark)
    this.render()
    this.send("PATCH", { keep: { remark } }, previous)
    return true
  }

  // From the toast, which goes away: focus comes back to the ribbon instead.
  openRemark(event) {
    this.opener = keyboardOpener(event) && this.buttonTarget
    this.hideToast()
    this.openPop()
  }

  togglePop() { this.popTarget.hidden ? this.openPop() : this.save() }

  openPop() {
    this.remarkTarget.value = this.kept.get(this.unitIdValue) ?? ""
    this.popTarget.hidden = false
    this.remarkTarget.focus()
  }

  close() { this.closePop(); giveBackFocus(this.opener, this.popTarget) }
  closePop() { this.popTarget.hidden = true }

  escape() {
    if (this.popTarget.hidden && this.toastTarget.hidden) return
    this.hideToast()
    if (!this.popTarget.hidden) this.cancel()
  }

  // A tap elsewhere saves an open popover (and the toast says so), or puts the toast away.
  away(event) {
    if (this.element.contains(event.target)) return
    if (this.popTarget.hidden) return this.hideToast()
    this.opener = null // focus stays with what was tapped
    this.save()
  }

  // Without a remark, the toast just kept offers one and Undo; with one, it shows what was saved
  // ("" when a remark was cleared).
  showToast(remark) {
    const saved = remark !== undefined
    this.toastRemarkTarget.hidden = !saved
    this.toastRemarkTarget.classList.toggle("cleared", remark === "")
    this.toastRemarkTarget.textContent = remark ? `“${remark}”` : "· remark cleared"
    this.toastKeptTargets.forEach(button => button.hidden = saved)
    this.toastSavedTarget.hidden = !saved || !remark
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
    const remark = this.kept.get(this.unitIdValue)
    this.buttonTarget.classList.toggle("kept", kept)
    this.buttonTarget.setAttribute("aria-pressed", kept)
    if (!kept) {
      this.buttonTarget.setAttribute("aria-label", "Keep this passage")
      this.buttonTarget.title = "Keep this passage (b)"
    } else if (remark) {
      this.buttonTarget.setAttribute("aria-label", `Kept: “${remark}”. Edit the remark or release`)
      this.buttonTarget.title = `Kept: “${remark}” (b)`
    } else {
      this.buttonTarget.setAttribute("aria-label", "Kept. Add a remark or release")
      this.buttonTarget.title = "Kept: add a remark or release (b)"
    }
  }

  announce(kept) {
    this.dispatch("changed", { detail: { unitId: this.unitIdValue, kept } })
  }

  // Send the change for the verse shown now; if it doesn't take, put the ribbon (or the remark) back as it was.
  async send(method, body, previousRemark) {
    const unitId = this.unitIdValue
    try {
      const response = await fetch(fillId(this.urlTemplateValue, unitId), {
        method,
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": csrfToken() },
        body: body && JSON.stringify(body),
        keepalive: true
      })
      // A redirect (to sign in) means nothing was saved, though fetch reports it ok.
      if (!response.ok || response.redirected) throw new Error(response.statusText)
    } catch {
      if (method === "PATCH") {
        // Unless it was released meanwhile, in which case there's no remark to restore.
        if (this.kept.has(unitId)) this.kept.set(unitId, previousRemark)
        if (unitId === this.unitIdValue) { this.render(); this.hideToast() }
        alert("Couldn't save your remark. Check your connection and try again.")
        return
      }
      const kept = method === "DELETE"
      if (kept) this.kept.set(unitId, ""); else this.kept.delete(unitId)
      if (unitId === this.unitIdValue) this.render()
      this.dispatch("changed", { detail: { unitId, kept } })
      alert("Couldn't save that. Check your connection and try again.")
    }
  }

  get isKept() { return this.kept.has(this.unitIdValue) }
}
