// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { clauseMode } from "lib/clauses"

import { configure } from "lexxy"
import "@rails/actiontext"

// Notes are prose: no uploads or attachments.
configure({ notes: { attachments: false } })

// Installable app: the (pass-through) service worker.
if ("serviceWorker" in navigator) navigator.serviceWorker.register("/service-worker.js").catch(() => {})

// Reading by clause lasts until you leave the reader.
document.addEventListener("turbo:load", () => {
  if (!document.querySelector("[data-controller~='lectio']")) clauseMode.set(null)
})
