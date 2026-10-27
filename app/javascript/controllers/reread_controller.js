import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken, fillId } from "lib/request"
import { focusAtEnd } from "lib/caret"

const VIEW_KEY = "reread-labels-view"
const SORT_KEY = "reread-picker-sort"
const PICKER_LEAST = 150, PICKER_TALLEST = 340 // px of the picker's cloud

// Rereading a focus's notes: one lit at a time down the column (j/k, the arrows, or a click), labelled with + label (l)
// or from the labels panel (c), which shows the labels in use as a cloud or as tallies. Pointing at a label lights the
// notes that carry it. The note you're on gets its editor, if it has one here (data-editor-url); where you are is
// saved, so the reread opens there again. A new note on the whole focus (n) is written in a row of its own, and a
// selection in the scratchpad can be made one ("Make a note of this"). A label's pill rereads only the notes carrying it
// (filter); there, Remove on the note you're on takes it off, the note staying (to put back) until you move on, and the
// band over the run names or renames the label (r). An
// archived focus's page is read-only (readOnly): moving, the labels panel and the scratchpad to read, nothing written
// or labelled.
export default class extends Controller {
  static targets = ["row", "newRow", "noteLabels", "labelsBody", "picker", "pickerInput", "pickerOptions", "pickerFoot", "labelForm", "pad", "labelsPanel",
    "lift", "toast", "count", "removed", "empty", "filterMenu", "band", "nameInput", "nameError"]
  static values = { positionUrl: String, labelsUrlTemplate: String, liftUrl: String, readOnly: Boolean, filter: String, renameUrl: String }

  connect() {
    let view = "cloud"
    try { view = localStorage.getItem(VIEW_KEY) || view } catch {}
    this.#setView(view)
    if (this.here) {
      this.#centre()
      // Turbo scrolls the page (to the top, or where it was) after it's rendered, so again once the visit is done.
      this.centreOnLoad = () => this.#centre()
      document.addEventListener("turbo:load", this.centreOnLoad, { once: true })
      this.#openEditor()
      // Opened on a note (?at=, from a pill or the band): the reread is there now.
      if (new URLSearchParams(location.search).has("at")) this.#savePosition()
    }
    this.#mark()
    this.letGoOnLeaving = () => this.#letGo()
    window.addEventListener("pagehide", this.letGoOnLeaving)
  }

  disconnect() {
    clearTimeout(this.saveTimer)
    document.removeEventListener("turbo:load", this.centreOnLoad)
    window.removeEventListener("pagehide", this.letGoOnLeaving)
    this.#letGo()
  }

  #centre() { this.here?.scrollIntoView({ block: "center" }) }
  centre() { this.#centre() }

  // While gathering what goes with a note (the compare controller), the column is that controller's.
  get #comparing() { return this.element.classList.contains("comparing") }

  // A note's chips or the panel were redrawn (labelling replies with both).
  noteLabelsTargetConnected() { this.#mark(); this.#recount() }
  labelsBodyTargetConnected() { this.#mark() }
  // The menu of labels to reread is drawn without knowing which is being reread: marked here.
  filterMenuTargetConnected() { this.#markMenu() }
  countTargetConnected() { this.#recount() }

  get here() { return this.rowTargets.find(row => row.classList.contains("here")) }

  // ---------- moving ----------

  next() { this.#step(1) }
  previous() { this.#step(-1) }

  pick(event) {
    const row = event.currentTarget
    if (this.#comparing || row.classList.contains("here") || event.target.closest("a, button")) return
    this.#go(row)
  }

  // Onto a note (from the compare controller).
  goTo(row) { if (row && row !== this.here) this.#go(row) }

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
    // A note just removed from the label being reread leaves the run, now you've moved on.
    if (left && left.dataset.noteId === this.removing) { this.#letGo({ render: true }); left.remove(); this.#recount() }
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
    if (this.readOnlyValue || this.#comparing) return
    const section = this.element.querySelector("#reread_free")
    if (!section) return
    // Out of the scratchpad (a phone's sheet, or the drawer at the right) and back to the notes, to write there.
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
    // Its editor loads from where it now saves, and its text shows in the row when you move on.
    row.dataset.editorUrl = element.action
    row.querySelector(".rr-note").id = `reread_text_note_${noteId}`
    // A note on the whole focus has a number now (a new one, if it was cleared and written again): the reply puts it here.
    row.querySelector(".rr-ref.rr-whole")?.setAttribute("id", "new_note_ref")
    if (row.classList.contains("rr-free")) delete row.dataset.cite
    if (fresh) {
      const labels = row.querySelector("[data-label-ids]")
      labels.id = `labels_note_${noteId}`
      labels.dataset.labelIds = ""
      labels.querySelectorAll(".rr-chip").forEach(el => el.remove())
    }
    this.#mark()
  }

  // Selecting some of the scratchpad offers "Make a note of this", just over the selection.
  selected() {
    if (this.readOnlyValue) return
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
      seen.set(word.dataset.labelName, { id: word.dataset.labelId, away: word.classList.contains("away"), title: word.title, used: Number(word.dataset.labelUsed) || 0 })
    })
    return seen
  }

  get #hereLabelIds() {
    return (this.here?.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ").filter(Boolean)
  }

  toggleLabel(event) {
    if (this.readOnlyValue) return
    const id = event.currentTarget.dataset.labelId
    if (!this.here) return
    if (this.#hereLabelIds.includes(id)) this.#submit("delete", id)
    else this.#submit("post", null, this.labelsPanelTarget.querySelector(`[data-label-id="${id}"][data-label-name]`).dataset.labelName)
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

  // ---------- rereading one label ----------

  // Remove, on the label's pill on the note you're on: crossed out, to put back, until you move on (or leave), when
  // it's taken off and the note leaves the run.
  remove(event) {
    event.stopPropagation()
    const noteId = event.currentTarget.closest(".rr-row")?.dataset.noteId
    if (!noteId) return
    this.removing = this.removing === noteId ? null : noteId
    this.#mark()
    this.#recount()
  }

  // Takes the label off the note just removed from it, if there is one. On the way off the page the reply isn't drawn.
  #letGo({ render = false } = {}) {
    const noteId = this.removing
    if (!noteId || !this.filterValue) return Promise.resolve()
    this.removing = null
    const sent = fetch(`${fillId(this.labelsUrlTemplateValue, noteId)}/${this.filterValue}`, {
      method: "DELETE", headers: { "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": csrfToken() }, keepalive: true
    })
    if (render) sent.then(response => response.ok && response.text()).then(html => html && Turbo.renderStreamMessage(html))
    return sent.catch(() => {})
  }

  // Following a pill, or a label in the menu: a note just removed from the label is taken off first, so the page you
  // come to has it off.
  async follow(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.button > 0) return
    event.preventDefault()
    event.stopPropagation()
    const href = event.currentTarget.href
    await this.#letGo()
    Turbo.visit(href)
  }

  // Back to all the notes (the band, or Esc), on the note you're on.
  async unfilter(event) {
    if (event && (event.metaKey || event.ctrlKey || event.shiftKey || event.button > 0)) return
    event?.preventDefault()
    const url = new URL(location.href)
    url.searchParams.delete("label")
    url.searchParams.delete("at")
    if (this.here?.dataset.noteId) url.searchParams.set("at", this.here.dataset.noteId)
    await this.#letGo()
    Turbo.visit(url.toString())
  }

  // The label being reread: its pills show all the notes again, and on the note you're on offer Remove (or, once
  // removed, Put back).
  #markFilter() {
    if (!this.filterValue) return
    this.element.querySelectorAll(`.rr-chip[data-label-id="${this.filterValue}"]`).forEach(chip => {
      chip.classList.add("current")
      const face = chip.querySelector(".rr-chip-face")
      const url = new URL(face.href)
      url.searchParams.delete("label")
      face.href = url.toString()
      face.title = "Show all the notes again"
      const take = chip.querySelector(".rr-chip-take")
      if (!take) return
      const removed = chip.closest(".rr-row")?.dataset.noteId === this.removing
      chip.classList.toggle("removed", removed)
      take.dataset.text ||= take.textContent
      take.dataset.title ||= take.title
      take.textContent = removed ? "Put back" : take.dataset.text
      take.title = removed ? "Put it back on this note" : take.dataset.title
    })
  }

  #markMenu() {
    this.filterMenuTarget.querySelectorAll(".menu-item").forEach(item => {
      if (item.dataset.labelId === this.filterValue) item.setAttribute("aria-current", "page")
      else item.removeAttribute("aria-current")
    })
  }

  // How many notes the label is on, here, and whether one was just removed.
  #recount() {
    if (!this.filterValue) return
    const n = this.rowTargets.filter(row => row.dataset.noteId !== this.removing &&
      (row.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ").includes(this.filterValue)).length
    this.countTargets.forEach(count => { count.textContent = `${n} ${n === 1 ? "note" : "notes"}` })
    this.removedTargets.forEach(removed => { removed.hidden = !this.removing })
    this.emptyTargets.forEach(empty => { empty.hidden = this.rowTargets.length > 0 })
  }

  // ---------- naming the label being reread ----------

  // The band turns into a field for the label's name: its name, or empty for an unnamed group.
  startNaming(event) {
    event?.stopPropagation()
    if (!this.hasNameInputTarget) return
    this.bandTarget.classList.add("naming")
    this.nameErrorTarget.hidden = true
    this.nameInputTarget.value = this.nameInputTarget.defaultValue
    this.nameInputTarget.focus()
    this.nameInputTarget.select()
  }

  stopNaming() {
    this.bandTarget.classList.remove("naming")
    this.bandTarget.querySelector(".rr-filter-rename button")?.focus()
  }

  // A blank name leaves it unnamed (a lettered group); a name already taken is refused, saying so, the field staying.
  async saveName(event) {
    event.preventDefault()
    const response = await fetch(this.renameUrlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": csrfToken() },
      body: JSON.stringify({ name: this.nameInputTarget.value })
    }).catch(() => null)
    if (!response?.ok) {
      this.nameErrorTarget.textContent = response?.status === 422 ? (await response.text()) || "That couldn't be done." : "That couldn't be done."
      this.nameErrorTarget.hidden = false
      return this.nameInputTarget.focus()
    }
    Turbo.renderStreamMessage(await response.text())
    this.bandTarget.classList.remove("naming")
  }

  // Esc leaves the name as it was, and goes no further (not back to all the notes).
  nameKey(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    event.stopPropagation()
    this.stopNaming()
  }

  // ---------- the picker ----------

  openPicker(event) {
    event?.stopPropagation()
    const add = this.here?.querySelector(".rr-add")
    if (!add) return
    this.pickerInputTarget.value = ""
    this.choice = -1
    this.#syncSort()
    this.pickerTarget.hidden = false
    this.filterPicker()
    this.#placePicker(add)
    this.pickerInputTarget.focus({ preventScroll: true })
  }

  // Under + label, unless that leaves room for only a row or two of labels and there's more above; the cloud shortened
  // to fit. On phones the scratchpad's handle takes the foot of the screen.
  #placePicker(add) {
    const picker = this.pickerTarget, cloud = this.pickerOptionsTarget
    const col = picker.offsetParent || picker.parentElement
    let floor = window.visualViewport?.height || window.innerHeight
    if (matchMedia("(max-width: 899px)").matches) floor = Math.min(floor, this.padTarget.getBoundingClientRect().top)
    // + label out of sight (l pressed with the lit note scrolled away): back into the middle first.
    const seen = add.getBoundingClientRect()
    if (seen.top < 0 || seen.bottom > floor) add.scrollIntoView({ block: "center" })
    const box = add.getBoundingClientRect(), colBox = col.getBoundingClientRect()
    const below = floor - box.bottom - 12, above = box.top - 12
    cloud.style.maxHeight = ""
    const chrome = picker.offsetHeight - cloud.offsetHeight
    const up = picker.offsetHeight > below && below - chrome < PICKER_LEAST && above > below
    cloud.style.maxHeight = `${Math.max(PICKER_LEAST, Math.min(PICKER_TALLEST, (up ? above : below) - chrome - 6))}px`
    picker.style.left = `${Math.max(0, Math.min(box.left - colBox.left, col.clientWidth - picker.offsetWidth - 16))}px`
    // Held by its foot when over + label, so it stays put as typing shortens the cloud.
    picker.style.top = up ? "" : `${box.bottom - colBox.top + 6}px`
    picker.style.bottom = up ? `${colBox.bottom - box.top + 6}px` : ""
    picker.classList.toggle("up", up)
  }

  // Your labels not yet on the note, A–Z or most recently used first, those under other focuses only among them,
  // narrowed to those holding what you typed. Enter takes the closest match (starting with it, then a word starting
  // with it, then holding it; the first among equals) or the one moved to with the arrows; with nothing typed,
  // nothing until you move. A new label of what you typed, unless it's one of yours already, waits in the footer, and
  // is what Enter takes when nothing matches.
  filterPicker() {
    const typed = this.pickerInputTarget.value.trim().replace(/\s+/g, " ")
    const q = typed.toLowerCase()
    const on = this.#hereLabelIds
    const order = this.#sort === "recent" ? (a, b) => b.used - a.used || a.name.localeCompare(b.name) : (a, b) => a.name.localeCompare(b.name)
    this.shown = [...this.#labels].map(([name, label]) => ({ name, ...label }))
      .filter(label => !on.includes(label.id) && label.name.toLowerCase().includes(q)).sort(order)
    this.fresh = typed && ![...this.#labels.keys()].some(name => name.toLowerCase() === q) ? typed : null

    if (typed && this.shown.length) {
      let best = 0
      this.shown.forEach((label, i) => { if (closeness(label.name, q) < closeness(this.shown[best].name, q)) best = i })
      this.choice = best
    } else this.choice = typed ? -1 : Math.min(this.choice, this.shown.length - 1)

    const words = this.shown.map((label, i) => {
      const word = document.createElement("button")
      word.type = "button"
      word.className = label.away ? "rr-pick away" : "rr-pick"
      word.setAttribute("role", "option")
      if (label.away) word.title = upcaseFirst(label.title.slice(label.name.length + 2)) // "Under Grace"
      const at = q ? label.name.toLowerCase().indexOf(q) : -1
      if (at >= 0) word.append(label.name.slice(0, at), Object.assign(document.createElement("mark"), { textContent: label.name.slice(at, at + q.length) }), label.name.slice(at + q.length))
      else word.textContent = label.name
      word.addEventListener("click", () => this.#choose(label.name))
      word.addEventListener("mouseenter", () => { this.choice = i; this.#markChoice() })
      return word
    })
    if (!words.length) {
      const none = document.createElement("p")
      none.className = "rr-pick-none"
      none.textContent = typed ? "No label holds that." : this.#labels.size ? "This note carries all your labels." : "No labels yet: type a name for one."
      words.push(none)
    }
    this.pickerOptionsTarget.replaceChildren(...words)
    this.#markChoice()
  }

  // The chosen label lit, and the footer saying what Enter does.
  #markChoice() {
    const words = this.pickerOptionsTarget.querySelectorAll(".rr-pick")
    words.forEach((word, i) => word.classList.toggle("chosen", i === this.choice))
    words[this.choice]?.scrollIntoView({ block: "nearest" })
    const parts = []
    if (this.choice >= 0) parts.push(`<span><kbd>↵</kbd> <b>${escapeHtml(this.shown[this.choice].name)}</b></span>`)
    else if (this.fresh) parts.push("<span><kbd>↵</kbd></span>")
    else parts.push("<span>Type to narrow, or <kbd>↓</kbd> to choose</span>")
    if (this.fresh) parts.push(`<button type="button" class="rr-pick-new${this.choice < 0 ? " chosen" : ""}">+ New label “${escapeHtml(this.fresh)}”</button>`)
    if (this.choice >= 0) parts.push("<span><kbd>↓</kbd><kbd>↑</kbd> to move</span>")
    this.pickerFootTarget.innerHTML = parts.join("")
    this.pickerFootTarget.querySelector(".rr-pick-new")?.addEventListener("click", () => this.#choose(this.fresh))
  }

  pickerKey(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const n = this.shown.length
      if (!n) return
      // After the last label, the new one (when there is one), then round again.
      const stops = this.fresh ? n + 1 : n
      let at = this.choice < 0 ? (this.fresh ? n : -1) : this.choice
      at = event.key === "ArrowDown" ? (at + 1) % stops : (at - 1 + stops) % stops
      this.choice = at === n ? -1 : at
      this.#markChoice()
    } else if (event.key === "Enter") {
      event.preventDefault()
      if (this.choice >= 0) this.#choose(this.shown[this.choice].name)
      else if (this.fresh) this.#choose(this.fresh)
    } else if (event.key === "Escape") {
      event.stopPropagation()
      this.#closePicker()
    }
  }

  sortPicker(event) {
    this.#sort = event.currentTarget.dataset.sort
    this.#syncSort()
    this.filterPicker()
    this.pickerInputTarget.focus()
  }

  get #sort() {
    try { return localStorage.getItem(SORT_KEY) || "alpha" } catch { return "alpha" }
  }

  set #sort(sort) {
    try { localStorage.setItem(SORT_KEY, sort) } catch {}
  }

  #syncSort() {
    const sort = this.#sort
    this.pickerTarget.querySelectorAll("[data-sort]").forEach(button => button.setAttribute("aria-pressed", button.dataset.sort === sort))
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
    this.#markFilter()
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
    if (this.#comparing && event.key !== "s" && event.key !== "c") return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    // One press is one step: holding a key down doesn't speed through the notes.
    if (event.key === "j" || event.key === "ArrowRight") { event.preventDefault(); if (!event.repeat) this.next() }
    else if (event.key === "k" || event.key === "ArrowLeft") { event.preventDefault(); if (!event.repeat) this.previous() }
    else if (event.key === "l") { event.preventDefault(); this.openPicker() }
    else if (event.key === "c") { event.preventDefault(); this.toggleLabels() }
    // Esc, with nothing else to put away, leaves the label being reread for all the notes.
    else if (event.key === "Escape" && this.filterValue && !this.padTarget.classList.contains("open") && this.pickerTarget.hidden &&
             !this.element.querySelector(".rr-filter-menu.open")) { event.preventDefault(); this.unfilter() }
    else if (event.key === "r" && this.hasNameInputTarget) { event.preventDefault(); this.startNaming() }
    else if (event.key === "n") { event.preventDefault(); this.newNote() }
    else if (event.key === "e") { const editor = this.here?.querySelector("lexxy-editor [contenteditable]"); if (editor) { event.preventDefault(); focusAtEnd(editor) } }
    else if (event.key === "s") {
      const pad = this.padTarget.querySelector(".composer lexxy-editor [contenteditable]")
      // Read-only, there's no editor to go into: it only comes out (or goes away again).
      if (this.readOnlyValue) { event.preventDefault(); return this.padTarget.querySelector(".panel-handle").click() }
      if (!pad) return
      event.preventDefault()
      // Put away (behind its tab, or a phone's sheet shut): out first.
      if (!this.padTarget.classList.contains("open")) this.padTarget.querySelector(".panel-handle").click()
      focusAtEnd(pad)
    }
  }
}

// How closely a label holds what's typed: starts with it, has a word starting with it, or only holds it.
function closeness(name, q) {
  const n = name.toLowerCase()
  return n.startsWith(q) ? 0 : n.split(/[\s-]+/).some(word => word.startsWith(q)) ? 1 : 2
}

const upcaseFirst = text => text.charAt(0).toUpperCase() + text.slice(1)
const escapeHtml = text => text.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
