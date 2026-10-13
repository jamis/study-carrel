import { Controller } from "@hotwired/stimulus"

// Submits its form as soon as a field in it changes, as each shelf's box under "Put on a shelf…" does. The reply draws
// the picker again, so the box is focused again afterward, to keep a keyboard user's place.
export default class extends Controller {
  submit() {
    const id = this.element.id
    document.addEventListener("turbo:before-stream-render", event => {
      const render = event.detail.render
      event.detail.render = async stream => {
        await render(stream)
        document.getElementById(id)?.querySelector("input[type=checkbox]")?.focus()
      }
    }, { once: true })
    this.element.requestSubmit()
  }
}
