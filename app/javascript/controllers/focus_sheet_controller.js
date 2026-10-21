import { Controller } from "@hotwired/stimulus"
import { focusAtEnd } from "lib/caret"

const TAB_KEY = "reader-sheet-tab"

// The reader's note sheet, turned between two tabs: the passage's note and the focus. The tab stays put as the verse
// changes, and for the sitting (sessionStorage); f turns it. The focus tab lists the notes on the whole focus, newest
// first, under a "+ New note" slip (n): a note opens as an editor in its place, one at a time, and stays open until
// Esc or another is opened; a new one left empty goes. A new note is made, and handed its number, by its first save
// (the reply puts its number in its head). On phones the sheet's handle shows the tab it's on.
export default class extends Controller {
  static targets = ["tab", "pane", "slip", "notes", "row", "newRow", "head", "count", "unitPreview", "focusPreview", "back"]
  static values = { next: Number, newUrl: String }

  connect() {
    this.focusText = ""
    this.#show(this.#stored === "focus" ? "focus" : "unit")
  }

  get tab() { return this.element.classList.contains("on-focus") ? "focus" : "unit" }

  pick(event) { this.#show(event.currentTarget.dataset.tab) }

  #show(tab) {
    this.element.classList.toggle("on-focus", tab === "focus")
    this.tabTargets.forEach(t => t.setAttribute("aria-selected", t.dataset.tab === tab))
    this.paneTargets.forEach(p => p.hidden = p.dataset.tab !== tab)
    this.#stored = tab
    this.#preview()
  }

  key(event) {
    if (event.target.closest("input, textarea, [contenteditable]") || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "f") { event.preventDefault(); this.#show(this.tab === "focus" ? "unit" : "focus") }
    else if (event.key === "n" && this.tab === "focus") { event.preventDefault(); this.newNote() }
  }

  // Esc while writing a note on the focus puts it away (before the phone's sheet would close). On the passage's note
  // under another focus, it goes back to the current focus's.
  escape(event) {
    if (this.tab === "unit" && this.hasBackTarget) {
      event.stopImmediatePropagation()
      const writing = !!event.target.closest?.("#note_editor [contenteditable]")
      this.backTarget.click()
      if (writing) this.#focusEditor()
      return
    }
    const row = this.openRow
    if (!row?.contains(event.target)) return
    event.stopImmediatePropagation()
    const fresh = row.classList.contains("fs-unsaved")
    this.#close()
    ;(row.isConnected && !fresh ? row.querySelector(".fs-open") : this.slipTarget).focus()
  }

  // ---------- the passage's note under another focus ----------

  // Chosen from the list under the focus (focus:chose): its note is on its way into the editor's frame.
  chose() {
    this.#show("unit")
    this.#openOnPhone()
    this.#focusEditor()
  }

  // Once the passage's editor has loaded, the caret at the end of it.
  #focusEditor() {
    const frame = document.getElementById("note_editor")
    frame?.addEventListener("turbo:frame-load", () => setTimeout(() => {
      const editor = frame.querySelector("lexxy-editor [contenteditable]")
      if (editor) focusAtEnd(editor)
    }), { once: true })
  }

  #openOnPhone() {
    const handle = this.element.querySelector(".panel-handle")
    if (handle.offsetParent && !this.element.classList.contains("open")) handle.click()
  }

  // ---------- the notes on the whole focus ----------

  // A new note in the slip's place, headed with the number it will likely be given.
  newNote() {
    this.#openOnPhone()
    const row = this.newRowTarget.content.firstElementChild.cloneNode(true)
    row.querySelector(".fs-num").textContent = `Focus ${this.nextValue}`
    this.notesTarget.prepend(row)
    this.#open(row)
  }

  open(event) { this.#open(event.currentTarget.closest(".fs-note")) }

  // Its editor, in its place, with the caret at the end; the one open before is put away.
  #open(row) {
    if (row === this.openRow) return
    this.#close()
    this.openRow = row
    this.focusText = ""
    row.classList.add("open")
    this.slipTarget.hidden = row.classList.contains("fs-unsaved")
    const frame = document.createElement("turbo-frame")
    frame.id = "focus_note_editor"
    frame.row = row // its last save comes as it's put away, out of the row
    frame.src = row.dataset.editorUrl
    frame.addEventListener("turbo:frame-load", () => setTimeout(() => {
      const editor = row.querySelector("lexxy-editor [contenteditable]")
      if (editor && this.openRow === row) focusAtEnd(editor)
      row.scrollIntoView({ block: "nearest" })
    }), { once: true })
    row.querySelector(".fs-editor").append(frame)
    this.#preview()
  }

  // Its editor goes, saving as it disconnects; its text stays in the row (the save's reply confirms it). A new note
  // left empty goes with it, as does one cleared.
  #close() {
    const row = this.openRow
    if (!row) return
    this.openRow = null
    const text = row.querySelector(".lexxy-editor__content")?.innerText.trim() ?? ""
    row.querySelector("turbo-frame")?.remove()
    row.classList.remove("open")
    if (text) row.querySelector(".fs-text").textContent = text
    else if (row.classList.contains("fs-unsaved")) row.remove()
    this.slipTarget.hidden = false
    this.#count()
  }

  // Leaving a new note while it's still empty puts the slip back.
  left(event) {
    const row = this.openRow
    if (!row?.classList.contains("fs-unsaved") || !row.contains(event.target) || row.contains(event.relatedTarget)) return
    setTimeout(() => {
      const empty = !row.querySelector(".lexxy-editor__content")?.textContent.trim()
      if (this.openRow === row && !row.contains(document.activeElement) && empty) this.#close()
    }, 150)
  }

  // A note on the whole focus saved (note:saved). A new one now has an id (a new one, if it was cleared and written
  // again): its editor reopens from where it saves, and the reply finds its head and text by it. Cleared, it's gone,
  // and writing again makes another; put away cleared, its row goes too.
  saved({ detail: { noteId, noted, element } }) {
    const row = element?.closest?.("turbo-frame#focus_note_editor")?.row
    if (!row?.isConnected) return
    if (noted && row.dataset.noteId !== noteId) {
      row.classList.remove("fs-unsaved")
      row.dataset.noteId = noteId
      row.dataset.editorUrl = element.action
      row.id = `focus_sheet_note_${noteId}`
      row.querySelector(".fs-meta").id = "new_focus_note_head"
      row.querySelector(".fs-text").id = `focus_sheet_text_note_${noteId}`
    } else if (!noted) {
      row.classList.add("fs-unsaved")
      delete row.dataset.noteId
      row.dataset.editorUrl = this.newUrlValue
      if (row !== this.openRow) row.remove()
    }
    this.#count()
  }

  // A head with its own number in it: the next new note will get a later one.
  headTargetConnected(head) {
    if (head.dataset.number) this.nextValue = Math.max(this.nextValue, Number(head.dataset.number) + 1)
  }

  #count() {
    const count = this.rowTargets.filter(row => !row.classList.contains("fs-unsaved")).length
    this.countTarget.textContent = count ? `(${count})` : ""
    this.#preview()
  }

  // ---------- the phone's handle ----------

  // The editors report their text as it loads and changes (note:text): the passage's, or the open note on the focus.
  text({ detail: { text, element } }) {
    if (element?.closest(".fs-note")) {
      this.focusText = text
      this.#preview()
    } else {
      this.unitPreviewTarget.textContent = text || "Write a note"
      this.unitPreviewTarget.classList.toggle("empty", !text)
    }
  }

  // On the focus tab: the open note's first line, or how many there are.
  #preview() {
    const count = this.rowTargets.filter(row => !row.classList.contains("fs-unsaved")).length
    const text = this.openRow ? this.focusText : ""
    this.focusPreviewTarget.textContent = text ||
      (count ? `${count} ${count === 1 ? "note" : "notes"} on the whole focus` : "No notes on the focus yet")
    this.focusPreviewTarget.classList.toggle("empty", !text)
  }

  // Storage can be unavailable (private windows, blocked site data); then the sheet opens on the passage's note.
  get #stored() {
    try { return sessionStorage.getItem(TAB_KEY) } catch { return null }
  }

  set #stored(tab) {
    try { sessionStorage.setItem(TAB_KEY, tab) } catch {}
  }
}
