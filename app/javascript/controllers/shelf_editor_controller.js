import { Controller } from "@hotwired/stimulus"

// The shelf editor (shelves/_form): the library tree with a box beside every collection and work. A ticked collection
// brings everything under it, so the boxes under it show ticked and greyed ("through Poetry") and, being disabled,
// aren't sent; unticking it clears them again. A collection with something ticked under it shows partly ticked.
// "On this shelf" lists what's ticked, each with a way to take it off, and the find box narrows the tree.
export default class extends Controller {
  static targets = ["box", "holding", "find"]

  connect() { this.refresh() }

  refresh() {
    // In document order, so a collection is settled before what's under it.
    for (const box of this.boxTargets) {
      const via = this.boxesAbove(box).find(b => b.checked && !b.disabled)
      if (via) {
        box.checked = true
        box.disabled = true
        box.dataset.through = via.dataset.name
      } else if ("through" in box.dataset) {
        box.checked = false
        box.disabled = false
        delete box.dataset.through
      }
    }
    for (const box of this.boxTargets) this.mark(box)
    this.list()
  }

  toggle(event) {
    const button = event.currentTarget
    const list = button.closest("li").querySelector(":scope > ul")
    list.hidden = !list.hidden
    button.setAttribute("aria-expanded", !list.hidden)
  }

  takeOff(event) {
    const box = this.boxTargets.find(b => b.value === event.currentTarget.dataset.key)
    if (box) box.checked = false
    this.refresh()
    this.holdingTarget.querySelector("button")?.focus()
  }

  // Narrows the tree to what matches, opening the collections a match is in. Everything in a matching collection
  // stays, folded as it was. Clearing the box puts every fold back as it was.
  find() {
    const query = this.findTarget.value.trim().toLowerCase()
    if (query && !this.folds) this.folds = new Map(this.lists.map(list => [ list, list.hidden ]))

    const visit = (node, inside) => {
      const matches = !query || node.dataset.find.includes(query)
      const list = node.querySelector(":scope > ul")
      let hit = false
      if (list) for (const kid of list.children) hit = visit(kid, inside || (query && matches)) || hit
      node.hidden = !(inside || matches || hit)
      if (list && query) list.hidden = hit ? false : this.folds.get(list)
      return matches && !!query || hit
    }
    for (const node of this.element.querySelectorAll(".shelf-tree > li")) visit(node, false)

    if (!query && this.folds) {
      for (const [ list, hidden ] of this.folds) list.hidden = hidden
      this.folds = null
    }
    this.lists.forEach(list => list.closest("li").querySelector(":scope > .tree-row .tree-toggle")?.setAttribute("aria-expanded", !list.hidden))
  }

  // Enter in the find box narrows the tree; it doesn't submit the shelf.
  stay(event) { event.preventDefault() }

  // A box's row: its note (through a collection, how much is ticked under it, or what it is) and partial tick.
  mark(box) {
    const row = box.closest(".tree-row")
    const meta = row.querySelector(".tree-meta")
    const below = this.boxesBelow(box).filter(b => b.checked && !b.disabled).length
    const on = box.checked && !box.disabled
    box.indeterminate = !box.checked && below > 0
    row.classList.toggle("on", on)
    row.classList.toggle("through", box.disabled)
    row.classList.toggle("some", box.indeterminate)
    meta.textContent = box.disabled ? `through ${box.dataset.through}`
      : box.indeterminate ? `${below} on the shelf`
      : meta.dataset.default
  }

  // "On this shelf": what's ticked, in library order, each with a way to take it off.
  list() {
    const ticked = this.boxTargets.filter(b => b.checked && !b.disabled)
    this.holdingTarget.replaceChildren(...ticked.map(box => {
      const chip = document.createElement("span")
      chip.className = "held"
      chip.textContent = box.dataset.name
      const button = document.createElement("button")
      button.type = "button"
      button.textContent = "×"
      button.dataset.key = box.value
      button.dataset.action = "shelf-editor#takeOff"
      button.setAttribute("aria-label", `Take ${box.dataset.name} off`)
      chip.append(button)
      return chip
    }))
    if (!ticked.length) {
      const empty = document.createElement("span")
      empty.className = "held-empty"
      empty.textContent = this.holdingTarget.dataset.empty
      this.holdingTarget.append(empty)
    }
  }

  boxesAbove(box) {
    const boxes = []
    for (let node = box.closest("li").parentElement.closest("li"); node && this.element.contains(node); node = node.parentElement.closest("li")) {
      const above = node.querySelector(":scope > .tree-row input[type=checkbox]")
      if (above) boxes.push(above)
    }
    return boxes
  }

  boxesBelow(box) { return [ ...box.closest("li").querySelectorAll(":scope > ul input[type=checkbox]") ] }

  get lists() { return [ ...this.element.querySelectorAll(".shelf-tree ul") ] }
}
