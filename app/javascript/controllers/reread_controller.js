import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken, fillId } from "lib/request"

const VIEW_KEY = "reread-labels-view"

// Rereading a focus's notes: one lit at a time down the column (j/k, the arrows, or a click), labelled with + label (l)
// or from the labels panel (c), which shows the labels in use as a cloud or as tallies. Pointing at a label lights the
// notes that carry it. The note you're on gets its editor, if it has one here (data-editor-url); where you are is
// saved, so the reread opens there again. A new note on the whole focus (n) is written in a row of its own, and a
// selection in the scratchpad can be made one ("Make a note of this").
export default class extends Controller {
  static targets = ["row", "newRow", "noteLabels", "labelsBody", "picker", "pickerInput", "pickerOptions", "labelForm", "pad", "labelsPanel",
    "lift", "toast"]
  static values = { positionUrl: String, labelsUrlTemplate: String, liftUrl: String }

  connect() {
    let view = "cloud"
    try { view = localStorage.getItem(VIEW_KEY) || view } catch {}
    this.#setView(view)
    if (this.here) {
      this.here.scrollIntoView({ block: "center" })
      this.#openEditor()
    }
    this.#mark()
  }

  disconnect() {
    clearTimeout(this.saveTimer)
  }

  // A note's chips or the panel were redrawn (labelling replies with both).
  noteLabelsTargetConnected() { this.#mark() }
  labelsBodyTargetConnected() { this.#mark() }

  get here() { return this.rowTargets.find(row => row.classList.contains("here")) }

  // ---------- moving ----------

  next() { this.#step(1) }
  previous() { this.#step(-1) }

  pick(event) {
    const row = event.currentTarget
    if (row.classList.contains("here") || event.target.closest("a, button")) return
    this.#go(row)
  }

  #step(by) {
    const rows = this.rowTargets
    const to = rows[rows.indexOf(this.here) + by]
    if (to) this.#go(to)
  }

  #go(row) {
    this.#closePicker()
    const left = this.here
    left?.classList.remove("here")
    row.classList.add("here")
    row.scrollIntoView({ block: "center", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" })
    // A new note left empty goes; one with words in it stays, and its editor's last save makes it.
    const unwritten = left?.classList.contains("rr-unsaved") && !left.querySelector(".lexxy-editor__content")?.textContent.trim()
    this.#openEditor()
    if (unwritten) left.remove()
    this.#mark()
    this.#savePosition()
  }

  // The note's editor, in the row you're on: the reader's for the current focus's notes on passages, its own for a note
  // on the whole focus. The old frame goes, so its editor saves as it disconnects, and a new one loads for this note.
  #openEditor() {
    this.element.querySelector("turbo-frame#note_editor")?.remove()
    const url = this.here.dataset.editorUrl
    if (!url) return
    const frame = document.createElement("turbo-frame")
    frame.id = "note_editor"
    frame.src = url
    this.here.querySelector(".rr-editor").append(frame)
  }

  // ---------- notes on the whole focus ----------

  newNote() {
    const section = this.element.querySelector("#reread_free")
    if (!section) return
    // On a phone, out of the scratchpad's sheet and back to the notes, to write there.
    if (this.padTarget.classList.contains("open")) this.padTarget.querySelector(".panel-handle").click()
    const row = this.newRowTarget.content.firstElementChild.cloneNode(true)
    section.append(row)
    this.#go(row)
    // Once its editor is in, into it, and the row (taller now) back to the middle: after the editor has scrolled its
    // caret into view, which would otherwise leave the row at the foot of the screen, under a phone's sheet.
    row.querySelector("turbo-frame").addEventListener("turbo:frame-load", () => {
      setTimeout(() => {
        const editor = row.querySelector("lexxy-editor [contenteditable]")
        if (editor) focusAtEnd(editor)
        setTimeout(() => row.scrollIntoView({ block: "center" }), 120)
      })
    }, { once: true })
  }

  // A note was saved (note:saved). A new note now has an id, to label and come back to; one cleared and written again
  // is a new note, without the old one's labels.
  saved({ detail: { noteId, element } }) {
    const row = element?.closest?.(".rr-row")
    if (!row || !noteId || row.dataset.noteId === noteId) return
    const fresh = !row.classList.contains("rr-unsaved")
    row.classList.remove("rr-unsaved")
    row.dataset.noteId = noteId
    row.id = `reread_note_${noteId}`
    if (fresh) {
      const labels = row.querySelector("[data-label-ids]")
      labels.id = `labels_note_${noteId}`
      labels.dataset.labelIds = ""
      labels.querySelectorAll(".rr-chip").forEach(chip => chip.remove())
    }
    this.#mark()
  }

  // Selecting some of the scratchpad offers "Make a note of this", just over the selection.
  selected() {
    const selection = getSelection()
    const range = selection.rangeCount && !selection.isCollapsed ? selection.getRangeAt(0) : null
    const inPad = range && this.padTarget.querySelector(".composer lexxy-editor")?.contains(range.commonAncestorContainer)
    if (!inPad || !selection.toString().trim()) { this.liftTarget.hidden = true; return }
    const box = range.getBoundingClientRect()
    this.liftTarget.style.left = `${box.left + box.width / 2}px`
    this.liftTarget.style.top = `${box.top}px`
    this.liftTarget.hidden = false
  }

  // Pressing the button mustn't take the selection away first.
  keepSelection(event) { event.preventDefault() }

  async lift() {
    const text = getSelection().toString().trim()
    this.liftTarget.hidden = true
    if (!text) return
    const content = text.split(/\n\s*\n|\n/).filter(line => line.trim()).map(line => `<p>${escapeHtml(line.trim())}</p>`).join("")
    const response = await fetch(this.liftUrlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": csrfToken() },
      body: JSON.stringify({ lift: true, note: { content } })
    })
    if (!response.ok) return this.#toast("Couldn't make a note of that.")
    const noteId = response.headers.get("X-Note-Id")
    Turbo.renderStreamMessage(await response.text())
    getSelection().removeAllRanges()
    this.#toast("Made a note on the whole focus.", "Go to it", () => {
      const row = this.element.querySelector(`#reread_note_${noteId}`)
      if (row) this.#go(row)
    })
  }

  #toast(text, action, act) {
    const toast = this.toastTarget
    toast.replaceChildren(text)
    if (action) {
      const button = document.createElement("button")
      button.type = "button"
      button.textContent = action
      button.addEventListener("click", () => { toast.hidden = true; act() })
      toast.append(" ", button)
    }
    toast.hidden = false
    clearTimeout(this.toastTimer)
    this.toastTimer = setTimeout(() => { toast.hidden = true }, 6000)
  }

  // Tell the server where the reread is (debounced), so it opens here next time.
  #savePosition() {
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      if (!this.here?.dataset.noteId) return
      fetch(this.positionUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ note_id: this.here.dataset.noteId }),
        keepalive: true
      })
    }, 600)
  }

  // ---------- labelling ----------

  // Every label the user has: the panel lists them all (those under other focuses too).
  get #labels() {
    const seen = new Map()
    this.labelsPanelTarget.querySelectorAll(".rr-cloud [data-label-name]").forEach(word => {
      seen.set(word.dataset.labelName, { id: word.dataset.labelId, away: word.classList.contains("away"), title: word.title })
    })
    return seen
  }

  get #hereLabelIds() {
    return (this.here?.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ").filter(Boolean)
  }

  toggleLabel(event) {
    const id = event.currentTarget.dataset.labelId
    if (!this.here) return
    if (this.#hereLabelIds.includes(id)) this.#submit("delete", id)
    else this.#submit("post", null, this.labelsPanelTarget.querySelector(`[data-label-id="${id}"][data-label-name]`).dataset.labelName)
  }

  unlabel(event) {
    event.stopPropagation()
    this.#submit("delete", event.currentTarget.dataset.labelId)
  }

  #submit(method, labelId, name) {
    if (!this.here?.dataset.noteId) return // a new note can be labelled once its first save makes it
    const form = this.labelFormTarget
    const base = fillId(this.labelsUrlTemplateValue, this.here.dataset.noteId)
    form.action = labelId ? `${base}/${labelId}` : base
    form.querySelector("[name=_method]")?.remove()
    if (method === "delete") form.insertAdjacentHTML("beforeend", '<input type="hidden" name="_method" value="delete">')
    form.querySelector("[name=name]").value = name || ""
    form.requestSubmit()
  }

  // ---------- the picker ----------

  openPicker(event) {
    event?.stopPropagation()
    const add = this.here?.querySelector(".rr-add")
    if (!add) return
    const picker = this.pickerTarget
    const col = picker.offsetParent || picker.parentElement
    const box = add.getBoundingClientRect(), colBox = col.getBoundingClientRect()
    picker.style.left = `${box.left - colBox.left}px`
    picker.style.top = `${box.bottom - colBox.top + col.scrollTop + 6}px`
    picker.hidden = false
    this.pickerInputTarget.value = ""
    this.choice = 0
    this.filterPicker()
    this.pickerInputTarget.focus()
  }

  filterPicker() {
    const typed = this.pickerInputTarget.value.trim().replace(/\s+/g, " ")
    const q = typed.toLowerCase()
    const on = this.#hereLabelIds
    const options = [...this.#labels].filter(([name, { id }]) => !on.includes(id) && name.toLowerCase().includes(q))
      .sort(([a, x], [b, y]) => x.away - y.away || a.localeCompare(b))
      .map(([name, { away, title }]) => ({ name, note: away ? title.replace(/^[^:]*: /, "") : "" }))
    if (typed && ![...this.#labels.keys()].some(name => name.toLowerCase() === q)) options.push({ name: typed, note: "new label" })
    this.options = options
    this.choice = Math.min(this.choice || 0, Math.max(0, options.length - 1))
    this.pickerOptionsTarget.replaceChildren(...options.map((option, i) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "rr-option"
      button.setAttribute("role", "option")
      button.setAttribute("aria-selected", i === this.choice)
      button.append(option.note === "new label" ? `New label “${option.name}”` : option.name)
      if (option.note && option.note !== "new label") {
        const small = document.createElement("small")
        small.textContent = option.note
        button.append(small)
      }
      button.addEventListener("click", () => this.#choose(option.name))
      return button
    }))
    if (!options.length) this.pickerOptionsTarget.innerHTML = `<p class="rr-option-none">Type a name for a new label</p>`
  }

  pickerKey(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const n = this.options.length
      if (!n) return
      this.choice = (this.choice + (event.key === "ArrowDown" ? 1 : -1) + n) % n
      this.pickerOptionsTarget.querySelectorAll(".rr-option").forEach((b, i) => b.setAttribute("aria-selected", i === this.choice))
    } else if (event.key === "Enter") {
      event.preventDefault()
      const option = this.options[this.choice]
      if (option) this.#choose(option.name)
    } else if (event.key === "Escape") {
      event.stopPropagation()
      this.#closePicker()
    }
  }

  #choose(name) {
    this.#closePicker()
    this.#submit("post", null, name)
  }

  #closePicker() {
    if (this.pickerTarget.hidden) return
    this.pickerTarget.hidden = true
    if (this.pickerTarget.contains(document.activeElement)) document.activeElement.blur()
  }

  away(event) {
    if (!this.pickerTarget.hidden && !this.pickerTarget.contains(event.target) && !event.target.closest(".rr-add")) this.#closePicker()
  }

  // ---------- the labels panel ----------

  toggleLabels() {
    const open = !this.padTarget.classList.contains("labels-open")
    this.padTarget.classList.toggle("labels-open", open)
    this.element.querySelectorAll(".rr-summon").forEach(b => b.setAttribute("aria-expanded", open))
  }

  view(event) {
    this.#setView(event.currentTarget.dataset.view)
    try { localStorage.setItem(VIEW_KEY, event.currentTarget.dataset.view) } catch {}
  }

  #setView(view) {
    this.padTarget.classList.toggle("show-tallies", view === "tallies")
    this.element.querySelectorAll("[data-view]").forEach(b => b.setAttribute("aria-pressed", b.dataset.view === view))
  }

  // The note you're on: its labels marked in the panel, its tick in the tallies taller.
  #mark() {
    const on = this.#hereLabelIds
    const noteId = this.here?.dataset.noteId
    this.labelsPanelTarget.querySelectorAll("[data-label-id]").forEach(el => el.classList.toggle("on", on.includes(el.dataset.labelId)))
    this.labelsPanelTarget.querySelectorAll(".rr-ticks i").forEach(tick => tick.classList.toggle("here", tick.dataset.noteId === noteId))
  }

  // Pointing at a label (in the panel) lights the notes that carry it.
  light(event) {
    const word = event.target.closest?.(".rr-labels-panel [data-label-id]")
    const id = word?.dataset.labelId
    if (id === this.lit) return
    this.lit = id
    this.element.classList.toggle("lighting", !!id)
    this.rowTargets.forEach(row => {
      const ids = (row.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ")
      row.classList.toggle("lit", !!id && ids.includes(id))
    })
  }

  // ---------- keys ----------

  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "Escape" && this.padTarget.classList.contains("labels-open") && this.pickerTarget.hidden) return this.toggleLabels()
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    if (event.key === "j" || event.key === "ArrowRight") { event.preventDefault(); this.next() }
    else if (event.key === "k" || event.key === "ArrowLeft") { event.preventDefault(); this.previous() }
    else if (event.key === "l") { event.preventDefault(); this.openPicker() }
    else if (event.key === "c") { event.preventDefault(); this.toggleLabels() }
    else if (event.key === "n") { event.preventDefault(); this.newNote() }
    else if (event.key === "e") { const editor = this.here?.querySelector("lexxy-editor [contenteditable]"); if (editor) { event.preventDefault(); focusAtEnd(editor) } }
    else if (event.key === "s") {
      const pad = this.padTarget.querySelector(".composer lexxy-editor [contenteditable]")
      if (!pad) return
      event.preventDefault()
      if (!this.padTarget.classList.contains("open") && matchMedia("(max-width: 899px)").matches) this.padTarget.querySelector(".panel-handle").click()
      focusAtEnd(pad)
    }
  }
}

const escapeHtml = text => text.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])

// Into an editor with the caret after what's written, to add to it.
function focusAtEnd(editable) {
  editable.focus({ preventScroll: true })
  const range = document.createRange()
  range.selectNodeContents(editable)
  range.collapse(false)
  const selection = getSelection()
  selection.removeAllRanges()
  selection.addRange(range)
}
