// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import { configure } from "lexxy"
import "@rails/actiontext"

// Notes are prose: no uploads or attachments.
configure({ notes: { attachments: false } })
