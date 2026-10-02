import { Controller } from "@hotwired/stimulus"

// Toggles light/dark. With no stored choice the CSS follows the system setting.
export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const dark = root.dataset.theme
      ? root.dataset.theme === "dark"
      : matchMedia("(prefers-color-scheme: dark)").matches
    const next = dark ? "light" : "dark"
    root.dataset.theme = next
    try { localStorage.setItem("study-theme", next) } catch {}
  }
}
